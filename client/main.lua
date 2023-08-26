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
local player, playerCoordsForDialogue, distance, distance2, question_entity_coords = PlayerPedId(), _GetEntityCoords(PlayerPedId()), {}, {}, nil
local EntitySliceInfinite = {
    Marker = {},
    Object = {},
    Dialogue = {}
}

--// Marker and Object handler //--
    -- Internal Functions
        ButtonNotificationInternal = function(msg, beep) -- Skip the multigsub function for faster execution
            _AddTextEntry('ButtonNotificationInternal', msg)
            _BeginTextCommandDisplayHelp('ButtonNotificationInternal')
            _EndTextCommandDisplayHelp(0, true, beep, -1)
        end

        CreateBlip = function(name, coords, sprite, colour, scale)
            local blip = AddBlipForCoord(coords)

            SetBlipSprite (blip, sprite)
            SetBlipScale  (blip, scale or 1.0)
            SetBlipColour (blip, colour)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(name)
            EndTextCommandSetBlipName(blip)
            return blip
        end

        -- Dialogues
            DrawDialogueTexts = function(questionCoords, playerCoords, dialogue)
                DrawText3Ds(questionCoords, dialogue.questions[1][dialogue.curQuestion], nil, nil, true)
                DrawText3Ds(playerCoords, dialogue.response.formatted[dialogue.curQuestion], nil, nil, true)
            end

            DrawLastQuestion = function(dialogue, time)
                -- Delete dialogue
                Utility.Cache.Dialogue[dialogue.entity] = nil                   
                TriggerEvent("Utility:DeleteDialogue", dialogue.entity)
        
                if dialogue.lastQuestion ~= nil then
                    local startTime = GetGameTimer()
        
                    CreateLoop(function(loopId)
                        local entityCoords = GetEntityCoords(dialogue.entity) + vector3(0.0, 0.0, 1.0)
                        
                        ClearPedTasks(dialogue.entity)
                        SetEntityAsMissionEntity(dialogue.entity)

                        DrawText3Ds(entityCoords, dialogue.lastQuestion, nil, nil, true)
        
                        if (GetGameTimer() - startTime) > time then
                            SetEntityAsNoLongerNeeded(dialogue.entity)
                            Utility.Cache.LastEntityDialogued = nil
                            StopLoop(loopId)
                        end
                    end)
                end
            end

            ItsLastQuestion = function(dialogue)
                return #dialogue.questions[1]+1 == dialogue.curQuestion
            end

            CheckDialogueInteraction = function(dialogue)
                for k,response in pairs(dialogue.response.no_formatted[dialogue.curQuestion]) do
                    if old_IsControlJustPressed(0, Keys[k:upper()]) then -- on key press
                        dialogue.callback(dialogue.curQuestion, response)

                        -- Switching to the next question
                        dialogue.curQuestion = dialogue.curQuestion + 1
                        
                        -- Prevent multiple interaction
                        Citizen.Wait(100)
                    end
                end
            end

            StopEntityWithIsTalking = function(entity)
                if Utility.Cache.LastEntityDialogued ~= entity then
                    if Utility.Cache.LastEntityDialogued then
                        SetEntityAsNoLongerNeeded(Utility.Cache.LastEntityDialogued)
                    end

                    ClearPedTasks(entity)
                    StopCurrentTaskAndWatchPlayer(entity)
                    SetEntityAsMissionEntity(entity)
                end

                Utility.Cache.LastEntityDialogued = entity
            end

        -- Markers
            DrawMarkerType = function(type, v)
                if type == 0 then
                    if v.text ~= "" then
                        DrawText3Ds(v.coords, v.text, v._scale or 0.35, v.font or 4, v.rect or false)
                    end
                elseif type == 1 then
                    local dir = v._direction or {x = 0.0, y = 0.0, z = 0.0}
                    local rot = v._rot or {x = 0.0, y = 0.0, z = 0.0}
                    local scale = v._scale or {x = 1.5, y = 1.5, z = 0.5}

                    _DrawMarker(v._type or 1, v.coords, dir.x or 0.0, dir.y or 0.0, dir.z or 0.0, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, scale.x or 1.5, scale.y or 1.5, scale.z or 0.5, v.rgb[1], v.rgb[2], v.rgb[3], v.alpha or 100, v.anim or false, false, 2, false, nil, nil, v.draw_entity or false)
                end
            end

            EnteredMarker = function(k, v)
                Emit("entered", false, "marker", k)
                v.near = true
            end

            LeavedMarker = function(k, v)
                Emit("leaved", false, "marker", k)
                v.near = false
            end

            DrawUtilityMarker = function(k,v)        
                if v.candraw then
                    local distance = #(GetEntityCoords(player) - v.coords)
                    local doingSomething = false

                    if distance < (v.render_distance or 0) then   
                        doingSomething = true                                
                        DrawMarkerType(v.type, v)
                    end
                    
                    if distance < v.interaction_distance then
                        if v.notify ~= nil then
                            ButtonNotificationInternal(v.notify, not v.near)
                        end

                        if not v.near then
                            EnteredMarker(k, v)
                        end
                    else
                        if v.near then
                            LeavedMarker(k, v)
                            ClearAllHelpMessages()
                        end
                    end

                    return doingSomething
                end
            end

            TryToDrawUtilityMarkers = function(slice)
                local drawing = false

                for k,v in pairs(Utility.Cache.Marker) do
                    if v.slice == slice then
                        if DrawUtilityMarker(k,v) then
                            drawing = true
                        end
                    end
                end

                return drawing
            end

            CheckIfCanView = function(jobs)
                if uPlayer then
                    if type(jobs) == "table" then
                        for i=1, #jobs do
                            if CurrentFramework == "Utility" then
                                for j=1, #uPlayer.jobs do
                                    if jobs[i] == uPlayer.jobs[j].name then
                                        return true
                                    end
                                end
                            else
                                if jobs[i] == uPlayer.job.name then
                                    return true
                                end
                            end
                        end
                    else
                        if CurrentFramework == "Utility" then
                            for i=1, #uPlayer.jobs do
                                if jobs == uPlayer.jobs[i].name then
                                    return true
                                end
                            end
                        else
                            if jobs == uPlayer.job.name then
                                return true
                            end 
                        end
                    end
                end
            end

            UpdateCanDraw = function(type)
                for k,v in pairs(Utility.Cache[type]) do
                    if v.job then
                        v.candraw = CheckIfCanView(v.job)
                    else
                        v.candraw = true
                    end
                end
            end

            RefreshDrawProperties = function()
                UpdateCanDraw("Marker")
                UpdateCanDraw("Object")
                UpdateCanDraw("Dialogue")
            end

            JobChange = function()
                for id,data in pairs(Utility.Cache.Blips) do
                    if CheckIfCanView(data.job) then
                        if not data.blip then
                            data.blip = CreateBlip(data.name, data.coords, data.sprite, data.colour, data.scale)
                        end
                    else
                        if data.blip then
                            RemoveBlip(data.blip)
                            data.blip = nil
                        end
                    end
                end

                RefreshDrawProperties()
            end

    -- Load Framework
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        
        if GetResourceState("es_extended") == "started" then
            CurrentFramework = "ESX"

            FW = exports["es_extended"]:getSharedObject()
            
            while FW.GetPlayerData().job == nil do
                Citizen.Wait(1)
            end
            
            uPlayer = FW.GetPlayerData()
            JobChange()
        
            RegisterNetEvent('esx:setJob', function(job)        
                uPlayer.job = job
                JobChange()
            end)
        elseif GetResourceState("qb-core") == "started" then
            CurrentFramework = "QB"

            QBCore = exports['qb-core']:GetCoreObject()

            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
                uPlayer = QBCore.Functions.GetPlayerData()
                JobChange()
            end)

            RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
                uPlayer.job = job
                JobChange()
            end)
        elseif GetResourceState("utility_framework") == "started" then
            CurrentFramework = "Utility"
            JobChange()
        end
    end) 

    -- Slice update check
    CreateLoop(function(loopId)
        currentSlice = tostring(GetSelfSlice())
        player = PlayerPedId()
    end, Config.UpdateCooldown)

    CreateLoop(function(loopId)
        local drawing = false

        if SliceUsed(currentSlice) then
            drawing = TryToDrawUtilityMarkers(currentSlice)
        end

        if next(EntitySliceInfinite.Marker) ~= nil then
            drawing = TryToDrawUtilityMarkers(-1)
        end

        if not drawing then
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)

    CreateLoop(function(loopId)
        if SliceUsed(currentSlice) then
            for k,v in pairs(Utility.Cache.Object) do
                if currentSlice == v.slice then
                    local distance = #(GetEntityCoords(player) - v.coords)
                    
                    if IsOnScreen(v.coords) then
                        local caninteract = true
                        
                        if v.job then
                            caninteract = CheckIfCanView(v.job)
                        end

                        if caninteract then
                            if distance < v.interaction_distance then
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
                end
            end
        end
    end, Config.UpdateCooldown)

    CreateLoop(function(loopId)
        local drawing = false

        if SliceUsed(currentSlice) then
            for entity,v in pairs(Utility.Cache.Dialogue) do
                if currentSlice == v.slice then
                    local questionCoords = _GetEntityCoords(entity) + vector3(0.0, 0.0, 1.0)
                    local playerCoords = _GetEntityCoords(player) + vector3(0.0, 0.0, 1.0)

                    if #(playerCoords - questionCoords) < v.distance then
                        drawing = true

                        if v.stopWhenTalking then
                            StopEntityWithIsTalking(entity)
                        end

                        if not ItsLastQuestion(v) then
                            DrawDialogueTexts(questionCoords, playerCoords, v)
                            CheckDialogueInteraction(v)
                        else
                            DrawLastQuestion(v, 3000)
                        end
                    end
                end
            end
        end

        if not drawing then
            if Utility.Cache.LastEntityDialogued then
                SetEntityAsNoLongerNeeded(Utility.Cache.LastEntityDialogued)
                Utility.Cache.LastEntityDialogued = nil
            end
            
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)

    CreateLoop(function(loopId)
        local drawing = false

        for k,v in pairs(Utility.Cache.N3d) do
            if v.show then
                drawing = true

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
                    else
                        rotation = vector3(0.0, 0.0, rot)
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
                    DrawScaleformMovie_3dNonAdditive(v.scaleform, scaleformCoords, rotation, 0.0, 1.0, 0.0, scaleformScale, 0)
                end
            end
        end

        if not drawing then
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
--// IsControlJustPressed Handler //--
    local Interaction = function()
        for k,v in _pairs(Utility.Cache.Marker) do
            local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)

            if v.near and distance < v.interaction_distance then
                Emit("marker", false, k)
                v.near = false
            end
        end

        for k,v in _pairs(Utility.Cache.Object) do
            local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)	
			
            if v.near and distance < v.interaction_distance then
                Emit("object", false, k)
                v.near = false
            end
        end
    end

    IsControlJustPressed("E", Interaction)
    IsControlJustPressed("L1_INDEX", Interaction)

--// Emit Handler //--
    function Emit(type, manual, ...)
        TriggerEvent("Utility:On:".. (manual and "!" or "") ..type, ...)
    end

--// Event //--
    RegisterNetEvent("Utility:SwapModel", function(coords, model, newmodel)
        RequestModel(newmodel)

        while not HasModelLoaded(newmodel) do
            Citizen.Wait(1)
        end

        CreateModelSwap(coords, 1.0, model, newmodel)
    end)

    RegisterNetEvent("Utility:StartParticleFxOnNetworkEntity", function(ptxAsset, name, obj, ...)
        RequestNamedPtfxAsset(ptxAsset)

        while not HasNamedPtfxAssetLoaded(ptxAsset) do
            Citizen.Wait(1)
        end

        SetPtfxAssetNextCall(ptxAsset)
        --print(name, obj, NetToObj(obj), GetEntityModel(NetToObj(obj)))
        StartNetworkedParticleFxLoopedOnEntity(name, NetToObj(obj), ...)
    end)

    RegisterNetEvent("Utility:FreezeNoNetworkedEntity", function(coords, model)
        local obj = GetClosestObjectOfType(coords, 3.0, model)

        if obj > 0 then
            FreezeEntityPosition(obj, true)
        end
    end)

    RegisterNetEvent("Utility:Create", function(type, id, table, res)
        if table.slice then
            if tostring(table.slice) == "-1" then
                EntitySliceInfinite[type][id] = true 
            end

            Utility.Cache.SliceGroups[tostring(table.slice)] = true
        end

        if table.job then
            table.candraw = CheckIfCanView(table.job)
        else
            table.candraw = true
        end

        Utility.Cache[type][id] = table 

        if type == "Blips" then
            JobChange()
        end
    end)

    RegisterNetEvent("Utility:Edit", function(type, id, field, new_data)
        if field == "slice" then
            -- Update used slice groups
            local oldSlice = Utility.Cache[type][id][field]
            local canClearOldSlice = true

            for k,v in pairs(Utility.Cache[type]) do
                if v.slice == oldSlice then
                    canClearOldSlice = false
                    break
                end
            end

            if canClearOldSlice then
                Utility.Cache.SliceGroups[oldSlice] = nil
            end

            Utility.Cache.SliceGroups[new_data] = true
        end

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
        if args[1] and args[2] then
            TriggerEvent("Utility:Pressed_"..args[1].."_"..args[2])
        end
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
