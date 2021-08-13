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

-- Why?, see that https://www.lua.org/gems/sample.pdf#page=3
local _TriggerServerEvent, _GetPlayerName, _PlayerId, _GetDistanceBetweenCoords, _DrawMarker, _GetEntityCoords, _pairs, _AddTextEntry, _BeginTextCommandDisplayHelp, _EndTextCommandDisplayHelp = TriggerServerEvent, GetPlayerName, PlayerId, GetDistanceBetweenCoords, DrawMarker, GetEntityCoords, pairs, AddTextEntry, BeginTextCommandDisplayHelp, EndTextCommandDisplayHelp

--// Marker and Object handler //--
    ButtonNotificationInternal = function(msg)
        _AddTextEntry('ButtonNotificationInternal', msg)
        _BeginTextCommandDisplayHelp('ButtonNotificationInternal')
        _EndTextCommandDisplayHelp(0, false, true, -1)
    end

    local player, playerCoords, playerCoordsForDialogue, distance, distance2, question_entity_coords = PlayerPedId(), _GetEntityCoords(PlayerPedId()), _GetEntityCoords(PlayerPedId()), {}, {}, nil

    CreateLoop(function(loopId)
        LoopThread(loopId, "utility_mainthread", Config.UpdateCooldown, function()
            player = PlayerPedId()
            playerCoords = _GetEntityCoords(player)

            for k,v in pairs(Utility.Cache.Marker) do
                distance[k] = #(playerCoords - v.coords)
            end

            for k,v in pairs(Utility.Cache.Object) do
                distance2[k] = #(playerCoords - v.coords)
            end
        end)

        for k,v in pairs(Utility.Cache.Marker) do
            if distance[k] ~= nil then
                
                if distance[k] < v.render_distance then
                    if v.type == 0 then
                        if v.text ~= "" then
                            DrawText3Ds(v.coords, v.text, v._scale or 0.35, v.font or 4, v.rect or false)
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

            LoopThread(loopId, "dialogue_thread", Config.UpdateDialogue, function()
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
                            TriggerEvent("Utility_Native:ResyncDialogue", k)
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

        for k,v in pairs(Utility.Cache.N3d) do
            if v.show then
                local scaleformCoords
                local scaleformScale
                local rotation = vector3(0.0, 0.0, 0.0)

                if v.advanced_scale then
                    scaleformScale = v.advanced_scale
                else
                    scaleformScale = vector3(v.scale*1, v.scale*(9/16), 1)
                end

                if v.attach ~= nil then
                    local rot = v.rotation.rotation or 0.0

                    if v.rotation.syncedwithplayer then
                        rotation = vector3(0.0, 0.0, -GetEntityHeading(v.attach.entity) + rot)
                    end
                    
                    local coords = GetOffsetFromEntityInWorldCoords(v.attach.entity, v.attach.offset.x, v.attach.offset.y, v.attach.offset.z)
                    
                    scaleformCoords = vector3(coords.x, coords.y, coords.z)
                else
                    local rot = v.rotation.rotation or 0.0

                    if v.rotation.syncedwithplayer then
                        rotation = vector3(0.0, 0.0, -GetEntityHeading(PlayerPedId()) + rot)
                    else
                        rotation = vector3(0.0, 0.0, rot)
                    end
                    
                    scaleformCoords = vector3(v.coords.x, v.coords.y, v.coords.z)
                end
                
                if v.scaleform ~= nil and HasScaleformMovieLoaded(v.scaleform) then
                    --                            handle           coords          rot      unk        scale      unk
                    DrawScaleformMovie_3dNonAdditive(v.scaleform, scaleformCoords, rotation, 0, 0, 0, scaleformScale, 0)
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
    RegisterNetEvent("Utility:Create", function(type, id, table, res)
        if type == "Emitter" then
            if Utility.Cache[type][id] == nil then
                Utility.Cache[type][id] = {}
            end

            -- Delete the old callback (prevent a bug that when you restart the script the utility try to call the old callback)
            for i=1, #Utility.Cache[type][id] do
                if Utility.Cache[type][id][i].res == res then
                    Utility.Cache[type][id][i] = nil
                end
            end

            Utility.Cache[type][id][#Utility.Cache[type][id] + 1] = table 
        else
            Utility.Cache[type][id] = table 
        end
    end)

    RegisterNetEvent("Utility:Edit", function(type, id, field, new_data)
        Utility.Cache[type][id][field] = new_data 
    end)

    RegisterNetEvent("Utility:Remove", function(type, id)
        Utility.Cache[type][id] = nil 
    end)

    RegisterNetEvent("Utility:FakeTrigger", function(type, id)
        Emit(type, true, id)
    end)

    if Config.EmitterTriggerForSyncedVariable then
        RegisterNetEvent("Utility:SyncValue_emit", function(name, old_value, value)
            Emit(name, false, value)
        end)
    end

    RegisterCommand('utility', function(_, args)
        TriggerEvent("Utility:Pressed_"..args[1])
    end, true)

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
