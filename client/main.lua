local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
local old_job = {}

-- Why?, see that https://www.lua.org/gems/sample.pdf#page=3
local _TriggerServerEvent, _GetPlayerName, _PlayerId, _GetDistanceBetweenCoords, _DrawMarker, _GetEntityCoords, _pairs, _AddTextEntry, _BeginTextCommandDisplayHelp, _EndTextCommandDisplayHelp = TriggerServerEvent, GetPlayerName, PlayerId, GetDistanceBetweenCoords, DrawMarker, GetEntityCoords, pairs, AddTextEntry, BeginTextCommandDisplayHelp, EndTextCommandDisplayHelp

--// Job //--
    Citizen.CreateThread(function()
        local player = PlayerPedId()

        while not HasCollisionLoadedAroundEntity(player) do
            Citizen.Wait(100)
        end

        StartESX()
        Citizen.Wait(100)

        old_job.job = xPlayer.job

        _TriggerServerEvent("Utility:AddWorker", xPlayer.job.name)
        if Config.SecondJob ~= "" then
            old_job[Config.SecondJob] = xPlayer[Config.SecondJob]
            _TriggerServerEvent("Utility:AddWorker", xPlayer[Config.SecondJob].name)
        end
    end)

    RegisterNetEvent('esx:setJob', function(job)
        local _s = source
        local old_work = old_job.job
        xPlayer.job = job
        old_job.job = job

        _TriggerServerEvent("Utility:RefreshWorker", old_work.name, job.name)
        Emit("job_change".._s, false, job.name)
    end)

    if Config.SecondJob ~= "" then
        RegisterNetEvent('esx:set'..Config.SecondJob:sub(1,1):upper()..Config.SecondJob:sub(2), function(data)
            local _s = source
            local old_work = old_job[Config.SecondJob]
            xPlayer[Config.SecondJob] = data
            old_job[Config.SecondJob] = data

            _TriggerServerEvent("Utility:RefreshWorker", old_work.name, data.name)
            Emit(Config.SecondJob.."_change_".._s, false, data.name)
        end)
    end


--// Marker and Object handler //--
    ButtonNotificationInternal = function(msg)
        _AddTextEntry('ButtonNotificationInternal', msg)
        _BeginTextCommandDisplayHelp('ButtonNotificationInternal')
        _EndTextCommandDisplayHelp(0, false, true, -1)
    end

    local player, playerCoords, playerCoordsForDialogue, distance, distance2, question_entity_coords = PlayerPedId(), _GetEntityCoords(PlayerPedId()), _GetEntityCoords(PlayerPedId()), {}, {}, nil

    CreateLoop(function()
        LoopThread("utility_mainthread",Config.UpdateCooldown, function()
            player = PlayerPedId()
            playerCoords = _GetEntityCoords(player)

            for k,v in pairs(Utility.Cache.Marker) do
                distance[k] = _GetDistanceBetweenCoords(playerCoords, v.coords, true)
            end

            for k,v in pairs(Utility.Cache.Object) do
                distance2[k] = _GetDistanceBetweenCoords(playerCoords, v.coords, true)
            end
        end)

        for k,v in pairs(Utility.Cache.Marker) do
            if distance[k] ~= nil then
                
                if distance[k] < v.render_distance then
                    if v.type == 0 then
                        if v.text ~= "" then
                            DrawText3Ds(v.coords, v.text, 0.35)
                        end
                    elseif v.type == 1 then
                        local dir = v._direction or {x = 0.0, y = 0.0, z = 0.0}
                        local rot = v._rot or {x = 0.0, y = 0.0, z = 0.0}
                        local scale = v._scale or {x = 1.5, y = 1.5, z = 0.5}

                        _DrawMarker(v._type or 1, v.coords, dir.x or 0.0, dir.y or 0.0, dir.z or 0.0, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, scale.x or 1.5, scale.y or 1.5, scale.z or 0.5, v.rgb[1], v.rgb[2], v.rgb[3], v.alpha or 100, v.anim or false, false, 2, false, nil, nil, v.draw_entity or false)
                    end
                end

                if distance[k] < v.interaction_distance then
                    if v.notify ~= nil then ButtonNotificationInternal(v.notify) end
                    if not v.near then
                        Emit("entered", false, "marker", k)
                        v.near = true
                    end
                else
                    if v.near then
                        Emit("leaved", false, "marker", k)
                        v.near = false
                    end
                end
            end
        end

        for k,v in pairs(Utility.Cache.Object) do
            if distance2[k] ~= nil then
                if distance2[k] < v.interaction_distance then
                    if not v.near then
                        Emit("entered", false, "object", k)
                        v.near = true
                    end
                    v.near = true
                else
                    if v.near then
                        Emit("leaved", false, "object", k)
                        v.near = false
                    end
                end
            end
        end

        for k,v in pairs(Utility.Cache.Dialogue) do
            -- k = handle
            if question_entity_coords == nil then question_entity_coords = _GetEntityCoords(v.entity) end

            LoopThread("dialogue_thread", 100, function()
                question_entity_coords = _GetEntityCoords(v.entity) + vector3(0.0, 0.0, 1.0)
                playerCoordsForDialogue = _GetEntityCoords(player) + vector3(0.0, 0.0, 1.0)
            end)

            if _GetDistanceBetweenCoords(playerCoordsForDialogue, question_entity_coords) < v.distance then
                DrawText3Ds(question_entity_coords, v.questions[1][v.current_question], nil, nil, true)
                DrawText3Ds(playerCoordsForDialogue, v.response.formatted[v.current_question], nil, nil, true)

                for k2,v2 in pairs(v.response.no_formatted[v.current_question]) do
                    if old_IsControlJustPressed(0, Keys[k2:upper()]) then
                        --developer("^3Interacted^0", "with the dialogue "..k, "[key "..k2.."]")

                        if #v.questions[1] == v.current_question then
                            v.callback(v.current_question, v2) -- Doing last callback
                            
                            -- Removing dialogue and resetting to default the question entity coords
                            Utility.Cache.Dialogue[k] = nil                            
                            --developer("^3Switching^0 [Last]", "question number", "from "..(v.current_question-1).." to "..v.current_question)

                            if v.lastq ~= nil then
                                local _entity = v.entity
                                local a = 0
                                CreateLoop(function()
                                    LoopThread(1, 1000, function()
                                        question_entity_coords = _GetEntityCoords(_entity) + vector3(0.0, 0.0, 1.0)
                                        a = a + 1
                                    end)

                                    if a == 3 then
                                        question_entity_coords = nil
                                        _break()
                                    else
                                        DrawText3Ds(question_entity_coords, v.lastq, nil, nil, true)
                                    end
                                end)
                            else
                                question_entity_coords = nil
                            end
                        else
                            v.callback(v.current_question, v2) -- Doing last callback

                            -- Switching to the next question
                            v.current_question = v.current_question + 1

                            --developer("^3Switching^0", "question number", "from "..(v.current_question-1).." to "..v.current_question)
                            
                            -- Prevent multiple interaction
                            Citizen.Wait(100)
                        end
                    end
                end
            end
        end
    end)

--// IsControlJustPressed Handler //--
    IsControlJustPressed("E", function()
        local InteractedWithSomething = false

        for k,v in _pairs(Utility.Cache.Marker) do
            if v.near then
                InteractedWithSomething = true
                Emit("marker", false, k)
                v.near = false
            end
        end

        for k,v in _pairs(Utility.Cache.Object) do
            if v.near then
                InteractedWithSomething = true
                Emit("object", false, k)
                v.near = false
            end
        end

        if InteractedWithSomething then
            DisableControlForSeconds("E", 1)
            Citizen.Wait(500)
        end
    end)

--// Emit Handler //--
    function Emit(type, manual, ...)
        local _emitter = Utility.Cache.Emitter
        if _emitter[type] == nil then
            return
        end

        if manual then 
            for i=1, #_emitter[type] do
                if _emitter[type][i].b then
                    _emitter[type][i].a(...)
                end
            end
        else
            for i=1, #_emitter[type] do
                _emitter[type][i].a(...)
            end
        end
    end

--// Event //--
    RegisterNetEvent("Utility:UpdateTable", function(name, table)
        Utility.Cache[name] = table
    end)

    RegisterNetEvent("Utility:FakeTrigger", function(type, id)
        Emit(type, true, id)
    end)

    RegisterCommand('utility', function(_, args)
        TriggerEvent("Utility:Pressed_"..args[1])
    end)

--// Test (dont unmark) //--
    --[[
        function CreateInternalLoop(tick)
            Citizen.CreateThread(function()
                while true do
                    for i=1, #Utility.Cache.Loop[tick] do
                        Utility.Cache.Loop[tick][i]()
                    end
                    Citizen.Wait(tonumber(tick))
                end
            end)
        end

        RegisterNetEvent("Utility:Loop", function(tick, cb)
            tick = tostring(tick)

            if Utility.Cache.Loop[tick] == nil then
                --print("tick "..tick.." dont exist, creating")
                Utility.Cache.Loop[tick] = {}
                CreateInternalLoop(tick)
            else
                --print("tick "..tick.." exist, inserting")
            end

            table.insert(Utility.Cache.Loop[tick], cb)
        end)
    ]]