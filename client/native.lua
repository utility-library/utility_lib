_G["ESX"], _G["xPlayer"], _G["source"], _G["developer"] = nil, nil, GetPlayerServerId(PlayerId()), function() end

-- Why?, see that https://www.lua.org/gems/sample.pdf#page=3
local _AddTextEntry, _BeginTextCommandDisplayHelp, _EndTextCommandDisplayHelp, _SetNotificationTextEntry, _AddTextComponentSubstringPlayerName, _DrawNotification, _GetEntityCoords, _World3dToScreen2d, _SetTextScale, _SetTextFont, _SetTextEntry, _SetTextCentre, _AddTextComponentString, _DrawText, _DoesEntityExist, _GetDistanceBetweenCoords, _GetPlayerPed, _TriggerEvent, _TriggerServerEvent = AddTextEntry, BeginTextCommandDisplayHelp, EndTextCommandDisplayHelp, SetNotificationTextEntry, AddTextComponentSubstringPlayerName, DrawNotification, GetEntityCoords, World3dToScreen2d, SetTextScale, SetTextFont, SetTextEntry, SetTextCentre, AddTextComponentString, DrawText, DoesEntityExist, GetDistanceBetweenCoords, GetPlayerPed, TriggerEvent, TriggerServerEvent

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

_G["Utility"] = {
    Cache = {
        PlayerPedId = PlayerPedId(),
        Marker = {},
        Object = {},
        Dialogue = {},
        
        Emitter = {},
        SetData = {},
	Frozen  = {}
    }
}


--// Emitter //--
    On = function(type, function_id, fake_triggerable)
        if string.find(type, "_change") then
            type = type..source
            -- job_change1
        end

        local _emitter = {
            res = GetCurrentResourceName(),
            a = function_id,
            b = fake_triggerable
        }

        _TriggerEvent("Utility:Create", "Emitter", type, _emitter, GetCurrentResourceName())
    end

--// Custom/Improved Native //-- 
    _G.old_TaskVehicleDriveToCoord = TaskVehicleDriveToCoord
    TaskVehicleDriveToCoord = function(ped, vehicle, destination, speed, stopRange)
        old_TaskVehicleDriveToCoord(ped, vehicle, destination, speed or 10.0, 0, GetEntityModel(vehicle), 2883621, stopRange or 1.0)
    end

    _G.old_DisableControlAction = DisableControlAction
    DisableControlAction = function(control, disable)
        return old_DisableControlAction(0, Keys[string.upper(control)], true or disable)
    end

    DisableControlForSeconds = function(control, seconds)
        local sec = seconds

        Citizen.CreateThread(function()
            while sec > 0 do
                Citizen.Wait(1000)
                sec = sec - 1
            end
            return
        end)

        Citizen.CreateThread(function()
            while sec > 0 do
                DisableControlAction(Keys[string.upper(control)])
                Citizen.Wait(1)
            end
            return
        end)
    end

    _G.old_IsControlJustPressed = IsControlJustPressed
    IsControlJustPressed = function(key, _function)
        developer("^2Created^0", "key map", key)
        RegisterKeyMapping('utility '..key, '', "keyboard", key)

        AddEventHandler("Utility:Pressed_"..key, _function)
    end

    ShowNotification = function(msg)
        _SetNotificationTextEntry('STRING')
        _AddTextComponentSubstringPlayerName(msg)
        _DrawNotification(false, true)
    end

    ButtonNotification = function(msg)
        if string.match(msg, "{.*}") then
            msg = string.multigsub(msg, {"{A}","{B}", "{C}", "{D}", "{E}", "{F}", "{G}", "{H}", "{L}", "{M}", "{N}", "{O}", "{P}", "{Q}", "{R}", "{S}", "{T}", "{U}", "{V}", "{W}", "{X}", "{Y}", "{Z}"}, {"~INPUT_VEH_FLY_YAW_LEFT~", "~INPUT_SPECIAL_ABILITY_SECONDARY~", "~INPUT_LOOK_BEHIND~", "~INPUT_MOVE_LR~", "~INPUT_CONTEXT~", "~INPUT_ARREST~", "~INPUT_DETONATE~", "~INPUT_VEH_ROOF~", "~INPUT_CELLPHONE_CAMERA_FOCUS_LOCK~", "~INPUT_INTERACTION_MENU~", "~INPUT_REPLAY_ENDPOINT~" , "~INPUT_FRONTEND_PAUSE~", "~INPUT_FRONTEND_LB~", "~INPUT_RELOAD~", "~INPUT_MOVE_DOWN_ONLY~", "~INPUT_MP_TEXT_CHAT_ALL~", "~INPUT_REPLAY_SCREENSHOT~", "~INPUT_NEXT_CAMERA~", "~INPUT_MOVE_UP_ONLY~", "~INPUT_VEH_HOTWIRE_LEFT~", "~INPUT_VEH_DUCK~", "~INPUT_MP_TEXT_CHAT_TEAM~", "~INPUT_HUD_SPECIAL~"})
        end
            
        _AddTextEntry('ButtonNotification', msg)
        _BeginTextCommandDisplayHelp('ButtonNotification')
        _EndTextCommandDisplayHelp(0, false, true, -1)
    end

    FloatingNotification = function(msg, coords)
        _AddTextEntry('FloatingNotification', msg)
        SetFloatingHelpTextWorldPosition(1, coords)
        SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
        _BeginTextCommandDisplayHelp('FloatingNotification')
        _EndTextCommandDisplayHelp(2, false, false, -1)
    end

    MakeEntityFaceEntity = function(entity1, entity2, whatentity)
        local coords1 = _GetEntityCoords(entity1, true)
        local coords2 = _GetEntityCoords(entity2, true)

        if whatentity then
            local heading = GetHeadingFromVector_2d(coords2.x - coords1.x, coords2.y - coords1.y)
            SetEntityHeading(entity1, heading)
        else
            local heading = GetHeadingFromVector_2d(coords1.x - coords2.x, coords1.y - coords2.y)
            SetEntityHeading(entity2, heading)
        end
    end

    DrawText3Ds = function(coords, text, scale, font, rectangle)
        local onScreen, _x, _y = _World3dToScreen2d(coords.x, coords.y, coords.z)

        if onScreen then
            _SetTextScale(scale or 0.35, scale or 0.35)
            _SetTextFont(font or 4)
            _SetTextEntry("STRING")
            _SetTextCentre(1)

            _AddTextComponentString(text)
            _DrawText(_x, _y)

            if rectangle then
                local factor = (string.len(text))/370
                DrawRect(_x, _y + 0.0125, 0.025+ factor, 0.025, 0, 0, 0, 90)
            end
        end
    end

    _G.old_TaskPlayAnim = TaskPlayAnim
    TaskPlayAnim = function(ped, animDictionary, ...)
        if not HasAnimDictLoaded(animDictionary) then
            RequestAnimDict(animDictionary)
            while not HasAnimDictLoaded(animDictionary) do Citizen.Wait(1) end
        end

        old_TaskPlayAnim(ped, animDictionary, ...)
        RemoveAnimDict(animDictionary)
    end

    _G.old_CreateObject = CreateObject
    CreateObject = function(modelHash, ...)
        if type(modelHash) == "string" then
            modelHash = GetHashKey(modelHash)
        end

        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash);
            while not HasModelLoaded(modelHash) do Citizen.Wait(1); end  
        end
        
        local obj = old_CreateObject(modelHash, ...)

        SetModelAsNoLongerNeeded(modelHash) 

        local netId = 0

        if NetworkGetEntityIsNetworked(obj) then
            netId = ObjToNet(obj)
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
        end

        return obj, netId
    end

    _G.old_CreatePed = CreatePed
    CreatePed = function(modelHash, ...)
        if type(modelHash) == "string" then
            modelHash = GetHashKey(modelHash)
        end

        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash);
            while not HasModelLoaded(modelHash) do Citizen.Wait(1); end
        end  

        local ped = old_CreatePed(0, modelHash, ...)
        SetModelAsNoLongerNeeded(modelHash) 

        local netId = 0

        if NetworkGetEntityIsNetworked(ped) then
            netId = PedToNet(ped)
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
        end

        return ped, netId
    end

    _G.old_CreateVehicle = CreateVehicle
    CreateVehicle = function(modelHash, ...)
        if type(modelHash) == "string" then
            modelHash = GetHashKey(modelHash)
        end

        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash);
            while not HasModelLoaded(modelHash) do Citizen.Wait(1); end
        end  

        local veh = old_CreateVehicle(modelHash, ...)
        SetModelAsNoLongerNeeded(modelHash) 

        local netId = 0

        if NetworkGetEntityIsNetworked(veh) then
            netId = VehToNet(veh)
            SetNetworkIdExistsOnAllMachines(netId, true)
            SetNetworkIdCanMigrate(netId, true)
        end

        return veh, netId
    end

    _G.old_DeleteEntity = DeleteEntity
    DeleteEntity = function(entity, isnetwork)
        if not isnetwork then
            NetworkRequestControlOfEntity(entity)
            -- entity = entityHandler
            while not NetworkRequestControlOfEntity(entity) do
                Citizen.Wait(1)
            end

            if not IsEntityAMissionEntity(entity) then
                SetEntityAsMissionEntity(entity)
            end

            old_DeleteEntity(entity)
        else
            -- entity = networkID
            NetworkRequestControlOfNetworkId(entity)
            
            local new_entity = NetworkGetEntityFromNetworkId(entity)

            while not NetworkRequestControlOfEntity(new_entity) do
                Citizen.Wait(1)
            end

            SetEntityAsMissionEntity(new_entity)
            old_DeleteEntity(new_entity)
        end
    end

    _G.old_RegisterNetEvent = RegisterNetEvent
    RegisterNetEvent = function(eventName, eventRoutine)
        old_RegisterNetEvent(eventName)
        AddEventHandler(eventName, eventRoutine)
    end

    _G.old_GetPlayerName = GetPlayerName
    GetPlayerName = function(id)
        return old_GetPlayerName(id or PlayerId())
    end

    _G.old_PlayerPedId = PlayerPedId
    PlayerPedId = function()
        if not _DoesEntityExist(Utility.Cache.PlayerPedId) then Utility.Cache.PlayerPedId = old_PlayerPedId() end
        return Utility.Cache.PlayerPedId
    end

    CreateLoop = function(_function, tickTime)
        Citizen.CreateThread(function()
            local active = true
            local NoAsync = {}
            _break = function()
                active = false
            end

            LoopThread = function(id, time, _function)
                if NoAsync[id] == nil then
                    NoAsync[id] = {a = true, b = false}
                end

                if NoAsync[id].a then
                    if not NoAsync[id].b then
                        NoAsync[id].b = true
                        Citizen.SetTimeout(time, function()
                            _function()
                            NoAsync[id].b = false
                        end)
                    end
                end
            end

            TaskBack = function(id, _function)
                LoopThread(id, 5000, function()
                    _function()
                end)
            end

            TaskSlow = function(id, _function)
                LoopThread(id, 1000, function()
                    _function()
                end)
            end

            TaskFast = function(id, _function)
                LoopThread(id, 500, function()
                    _function()
                end)
            end

            TaskExtrafast = function(id, _function)
                LoopThread(id, 5, function()
                    _function()
                end)
            end

            StopLoopThread = function(id)
                NoAsync[id].a = false
            end

            ResumeLoopThread = function(id)
                NoAsync[id].a = true
            end

            while active do
                _function()
                Citizen.Wait(tickTime or 5)
            end
        end)
    end

    GetWorldClosestPed = function(radius)
        local closest = 0
        local AllFoundedPed = GetGamePool("CPed")
        local coords = _GetEntityCoords(PlayerPedId())
        local minDistance = radius + 5.0

        for i=1, #AllFoundedPed do
            local distance = _GetDistanceBetweenCoords(coords, _GetEntityCoords(AllFoundedPed[i]), false)

            if distance <= radius and AllFoundedPed[i] ~= PlayerPedId() then
                if minDistance > distance then
                    minDistance = distance
                    closest = AllFoundedPed[i]
                end
            end
        end

        return closest, AllFoundedPed
    end

    GetWorldClosestPlayer = function(radius)
        local closest = 0
        local AllPlayers = {}
        local minDistance = radius + 5.0

        local AllFoundedPed = GetGamePool("CPed")
        
        local coords = _GetEntityCoords(PlayerPedId())

        for i=1, #AllFoundedPed do
            if IsPedAPlayer(AllFoundedPed[i]) then
                table.insert(AllPlayers, NetworkGetPlayerIndexFromPed(AllFoundedPed[i]))

                local distance = _GetDistanceBetweenCoords(coords, _GetEntityCoords(AllFoundedPed[i]), false)

                if distance <= radius and AllFoundedPed[i] ~= PlayerPedId() then
                    if minDistance > distance then
                        minDistance = distance
                        closest = NetworkGetPlayerIndexFromPed(AllFoundedPed[i])
                    end
                end
            end
        end

        return closest, AllPlayers
    end

    GetEntitySurfaceMaterial = function(entity)
        local coords = GetEntityCoords(entity)

        local shape_result = StartShapeTestCapsule(coords.x,coords.y,coords.z,coords.x,coords.y,coords.z-2.5, 2, 1, entity, 7)
        local _, hitted, _, _, materialHash = GetShapeTestResultIncludingMaterial(shape_result)

        return materialHash, hitted
    end

    GetLoadoutOfPed = function(ped)
        local list = ESX.GetWeaponList()
        local loadout = {}

        for i=1, #list, 1 do
            local hash = GetHashKey(list.name)

            if HasPedGotWeapon(ped, hash, false) then
                table.insert(loadout, {name = list.name, hash = hash, ammo = GetAmmoInPedWeapon(ped, hash)})
            end
        end

        return loadout
    end

    local old_FreezeEntityPosition = FreezeEntityPosition
    FreezeEntityPosition = function(entity, active)
        Utility.Cache.Frozen[entity] = active
        old_FreezeEntityPosition(entity, active)
    end

    IsEntityFrozen = function(entity)
        return Utility.Cache.Frozen[entity] == true
    end

--// Synced Trigger //--
    TriggerSyncedEvent = function(event, whitelist, ...)
        if type(whitelist) == "number" or type(whitelist) == "table" then
            if whitelist == -1 then
                _TriggerServerEvent("Utility:SyncEvent", event, "", ...)
            else
                _TriggerServerEvent("Utility:SyncEvent", event, whitelist, ...) 
            end
        else
            developer("^2Error", "you can use only number/table on whitelist of TriggerSyncedEvent", "")
        end
    end

--// ESX integration //--
    -- Init
        StartESX = function(eventName, second_job)
            -- I did it this way because the thread is interpreted after the script is loaded (after the main thread)
            -- to avoid weird bugs where esx does not load (remains nil)
            -- and not being able to use "while ESX == nil do" since i don't want to make it work only in one thread (so being able to use esx only in that thread) 
            -- I go around the problem by calling it 100 times if it's zero (i know is a bad solution but is the only one)

            TriggerEvent(eventName or 'esx:getSharedObject', function(obj) ESX = obj end)

            for i=1, 100 do
                if ESX == nil then
                    TriggerEvent(eventName or 'esx:getSharedObject', function(obj) ESX = obj end)
                end
            end
        
            if second_job ~= nil then
                RegisterNetEvent('esx:set'..string.upper(second_job:sub(1,1))..second_job:sub(2), function(job)        
                    xPlayer[second_job] = job
                end)
            end
        
            RegisterNetEvent('esx:setJob', function(job)        
                xPlayer.job = job
            end)
        
            xPlayer = ESX.GetPlayerData()
        end

    -- Job
        GetDataForJob = function(job)
            local job_info = nil

            ESX.TriggerServerCallback("Utility:GetJobData", function(worker)
                job_info = worker
            end, job)

            while job_info == nil do
                Citizen.Wait(1)
            end

            return #job_info, job_info
        end

--// Advanced script creation //--
    local _GetOnHandObject = 0

    GetOnHandObject = function()
        return _GetOnHandObject
    end

    TakeObjectOnHand = function(ped, entityToGrab, zOffset, xPos, yPos, zPos, xRot, yRot, zRot)
        developer("^2Taking^0", "object", entityToGrab.." ("..GetEntityModel(entityToGrab)..")")

        if type(entityToGrab) == "number" then -- Send an entity ID (Use already exist entity)
            TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 3.0, 3.0, -1, 63, 0, 0, 0, 0)
            Citizen.Wait(100)
            AttachEntityToEntity(entityToGrab, ped, GetPedBoneIndex(ped, 60309), xPos or 0.2, yPos or 0.08, zPos or 0.2, xRot or -45.0, yRot or 290.0, zRot or 0.0, true, true, false, true, 1, true)

            _GetOnHandObject = entityToGrab
        elseif type(entityToGrab) == "string" then -- Send a model name (New object created)
            local coords = _GetEntityCoords(ped)      
            local prop = CreateObject(entityToGrab, coords + vector3(0.0, 0.0, zOffset or 0.2), true, false, false)
            
            SetEntityAsMissionEntity(prop)
            TaskPlayAnim(ped, "anim@heists@box_carry@", "idle", 3.0, -8, -1, 63, 0, 0, 0, 0)
            Citizen.Wait(100)
            AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), xPos or 0.2, yPos or 0.08, zPos or 0.2, xRot or -45.0, yRot or 290.0, zRot or 0.0, true, true, false, true, 1, true)

            _GetOnHandObject = prop
            return prop
        end
    end

    DropObjectFromHand = function(entityToDrop, delete)
        if delete then
            developer("^1Deleting^0","from hand", entityToDrop)

            DeleteEntity(entityToDrop)
        else
            developer("^3Dont delete^0","from hand", entityToDrop)

            DetachEntity(entityToDrop)
            SetEntityCoords(entityToDrop, GetOffsetFromEntityInWorldCoords(entityToDrop, 0, 0.5, 0))
            PlaceObjectOnGroundProperly(entityToDrop)
            FreezeEntityPosition(entityToDrop, true)
        end

        ClearPedTasks(PlayerPedId())
        _GetOnHandObject = 0
    end

--// Managing data (like table, but more easy to use) //--

    SetFor = function(id, property, value)
        -- If id dont already exist register it for store data
        if Utility.Cache["SetData"][id] == nil then
            Utility.Cache["SetData"][id] = {}
        end

        if type(property) == "table" then -- Table
            for k,v in pairs(property) do
                developer("^2Setting^0", "data", "("..id..") ["..k.." = "..json.encode(v).."] {table}")
                Utility.Cache["SetData"][id][k] = v
            end
        else -- Single
            developer("^2Setting^0", "data", "("..id..") ["..property.." = "..json.encode(value).."] {single}")
            Utility.Cache["SetData"][id][property] = value
        end
    end

    GetFrom = function(id, property)
        if property == nil then
            property = "not defined"
        end

        developer("^3Getting^0", "data", "("..id..") ["..property.."]")

        if Utility.Cache["SetData"][id] ~= nil then
            if property == "not defined" then
                return Utility.Cache["SetData"][id]
            else
                return Utility.Cache["SetData"][id][property]
            end
        else
            return nil
        end
    end

    _g = function(name, value)
        TriggerEvent("Utility:RegisterGlobal", name, value)
    end

    RegisterNetEvent("Utility:RegisterGlobal", function(name, value)
        _G[name] = value
    end)

--// Marker/Object/Blip //--
    -- Marker
    RandomId = function(length)
        length = length or 5

        local maxvalue = ""

        for i=1, length do
            maxvalue = maxvalue.."9"
        end

        return math.random(0, maxvalue)
    end

    CreateMarker = function(id, coords, render_distance, interaction_distance, options)
        if DoesExist("m", id) then
            Citizen.Wait(100)
            return
        else
            id = string.gsub(id, "{r}", RandomId())

            developer("^2Created^0","Marker",id)

            local _marker = {
                render_distance = render_distance,
                interaction_distance = interaction_distance,
                coords = coords
            }

            -- Options

            if type(options) == "table" then
                if options.rgb ~= nil then -- Marker
                    _marker.type = 1
                    _marker.rgb = options.rgb
                elseif options.text ~= nil then -- 3d Text
                    _marker.type = 0
                    _marker.text = options.text
                    _TriggerEvent("Utility:Create", "Marker", id, _marker)
                    return
                else
                    _marker.type = 1
                    _marker.rgb = {options[1], options[2], options[3]}
                    _TriggerEvent("Utility:Create", "Marker", id, _marker)
                    return
                end
                
                if options.type ~= nil and type(options.type) == "number" then _marker._type = options.type end
                if options.direction ~= nil and type(options.direction) == "vector3" then _marker._direction = options.direction end
                if options.rotation ~= nil and type(options.rotation) == "vector3" then _marker._rot = options.rotation end
                if options.scale ~= nil and type(options.scale) == "vector3" then _marker._scale = options.scale end
                if options.alpha ~= nil and type(options.alpha) == "number" then _marker.alpha = options.alpha end
                if options.animation ~= nil and type(options.animation) == "boolean" then _marker.anim = options.animation end

                if options.notify ~= nil then
                    local notify = string.multigsub(options.notify, {"{A}","{B}", "{C}", "{D}", "{E}", "{F}", "{G}", "{H}", "{L}", "{M}", "{N}", "{O}", "{P}", "{Q}", "{R}", "{S}", "{T}", "{U}", "{V}", "{W}", "{X}", "{Y}", "{Z}"}, {"~INPUT_VEH_FLY_YAW_LEFT~", "~INPUT_SPECIAL_ABILITY_SECONDARY~", "~INPUT_LOOK_BEHIND~", "~INPUT_MOVE_LR~", "~INPUT_CONTEXT~", "~INPUT_ARREST~", "~INPUT_DETONATE~", "~INPUT_VEH_ROOF~", "~INPUT_CELLPHONE_CAMERA_FOCUS_LOCK~", "~INPUT_INTERACTION_MENU~", "~INPUT_REPLAY_ENDPOINT~" , "~INPUT_FRONTEND_PAUSE~", "~INPUT_FRONTEND_LB~", "~INPUT_RELOAD~", "~INPUT_MOVE_DOWN_ONLY~", "~INPUT_MP_TEXT_CHAT_ALL~", "~INPUT_REPLAY_SCREENSHOT~", "~INPUT_NEXT_CAMERA~", "~INPUT_MOVE_UP_ONLY~", "~INPUT_VEH_HOTWIRE_LEFT~", "~INPUT_VEH_DUCK~", "~INPUT_MP_TEXT_CHAT_TEAM~", "~INPUT_HUD_SPECIAL~"})
                    _marker.notify = notify
                end
            elseif type(options) == "string" then
                _marker.type = 0
                _marker.text = options
            end
            
            Utility.Cache.Marker[id] = _marker -- Sync the local table
            _TriggerEvent("Utility:Create", "Marker", id, _marker) -- Sync the table in the utility_lib
        end
    end

        SetMarkerType = function(id, _type)
            if type(_type) ~= "number" then
                developer("^1Error^0","Type can be only a number", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id]._type = _type
                _TriggerEvent("Utility:Edit", "Marker", id, "_type", _type)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerDirection = function(id, direction)
            if type(direction) ~= "vector3" then
                developer("^1Error^0","Direction can be only a vector3", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id]._direction = direction
                _TriggerEvent("Utility:Edit", "Marker", id, "_direction", direction)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerRotation = function(id, rot)
            if type(rot) ~= "vector3" then
                developer("^1Error^0","Rotation can be only a vector3", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id]._rot = rot
                _TriggerEvent("Utility:Edit", "Marker", id, "_rot", rot)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerScale = function(id, scale)
            if type(scale) ~= "vector3" then
                developer("^1Error^0","Scale can be only a vector3", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id]._scale = scale
                _TriggerEvent("Utility:Edit", "Marker", id, "_scale", scale)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerColor = function(id, rgb)
            if type(rgb) ~= "table" then
                developer("^1Error^0","Color can be only a vector3", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].rgb = rgb
                _TriggerEvent("Utility:Edit", "Marker", id, "rgb", rgb)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerAlpha = function(id, alpha)
            if type(alpha) ~= "number" then
                developer("^1Error^0","Alpha can be only a number", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].alpha = alpha
                _TriggerEvent("Utility:Edit", "Marker", id, "alpha", alpha)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerAnimation = function(id, active)
            if type(active) ~= "boolean" then
                developer("^1Error  ^0","Animation can be only a boolean (true/false)", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].anim = active
                _TriggerEvent("Utility:Edit", "Marker", id, "anim", active)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerDrawOnEntity = function(id, active)
            if type(active) ~= "boolean" then
                developer("^1Error^0","Draw on entity can be only a boolean (true/false)", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].draw_entity = active
                _TriggerEvent("Utility:Edit", "Marker", id, "draw_entity", active)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        -- 3dText
        Set3dTextScale = function(id, scale)
            if type(scale) ~= "number" then
                developer("^1Error^0","Marker scale can be only a number", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id]._scale = scale
                _TriggerEvent("Utility:Edit", "Marker", id, "_scale", scale)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        Set3dTextDrawRect = function(id, active)
            if type(active) ~= "boolean" then
                developer("^1Error^0","Marker rect can be only a boolean (true/false)", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].rect = active
                _TriggerEvent("Utility:Edit", "Marker", id, "rect", active)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        Set3dTextFont = function(id, font)
            if type(font) ~= "number" then
                developer("^1Error^0","Marker font can be only a number", "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id].font = font
                _TriggerEvent("Utility:Edit", "Marker", id, "font", font)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

    DeleteMarker = function(id)
        if not DoesExist("m", id) then
            Citizen.Wait(100)
            return
        else
            developer("^1Deleted^0","Marker",id)
            Utility.Cache.Marker[id] = nil
            _TriggerEvent("Utility:Remove", "Marker", id)
        end
    end

    -- Object
    CreateiObject = function(id, model, pos, heading, interaction_distance, network)
        developer("^2Created^0 Object "..id.." ("..model..")")

        local obj = CreateObject(GetHashKey(model), pos.x,pos.y,pos.z, network or true, false, false) or nil
        SetEntityHeading(obj, heading)
        SetEntityAsMissionEntity(obj, true, true)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(hash)

        _object = {
            obj = obj,
            coords = pos,
            interaction_distance = interaction_distance or 3.0
        }

        Utility.Cache.Object[id] = _object -- Sync the local table
        _TriggerEvent("Utility:Create", "Object", id, _object) -- Sync the table in the utility_lib
        return obj, _GetEntityCoords(obj)
    end

    DeleteiObject = function(id, delete)
        developer("^1Deleted^0","Object",id)

        if delete then
            DeleteEntity(Utility.Cache.Object[id].obj)
        end

        Utility.Cache.Object[id] = nil
        _TriggerEvent("Utility:Remove", "Object", id)
    end

    -- Blip
    CreateBlip = function(name, coords, sprite, colour, scale)
        developer("^2Created^0","Blip",name)
        local blip = AddBlipForCoord(coords)

        SetBlipSprite (blip, sprite)
        SetBlipScale  (blip, scale or 1.0)
        SetBlipColour (blip, colour)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
        _AddTextComponentSubstringPlayerName(name)
        EndTextCommandSetBlipName(blip)
        return blip
    end

    -- Get/Edit
    SetIdOf = function(type, id, new_id)
        if type:lower() == "marker" or type:lower() == "m" then
            type = "Marker"
        elseif type:lower() == "object" or type:lower() == "o" then
            type = "Object"
        else
            return nil
        end
        
        if DoesExist(type, id) then
            Utility.Cache[type][new_id] = Utility.Cache[type][id]

            Utility.Cache[type][id] = nil
        else
            developer("^1Error^0", "Unable to set id of the "..type.." as it does not exist", id)
            return
        end

        developer("^3Change^0", "Setted id to "..new_id.." of the id", id)

        _TriggerEvent("Utility:Remove", type, id)
        _TriggerEvent("Utility:Create", type, new_id, Utility.Cache[type][new_id]) -- Sync the table in the utility_lib
    end

    SetTextOf = function(type, id, new_text)
        if type:lower() == "marker" or type:lower() == "m" then
            type = "Marker"
        elseif type:lower() == "object" or type:lower() == "o" then
            type = "Object"
        else
            return nil
        end
        
        if DoesExist(type, id) then
            Utility.Cache[type][id].text = new_text
            _TriggerEvent("Utility:Edit", type, id, "text", new_text)
        else
            developer("^1Error^0", "Unable to change text of the "..type.." as it does not exist", id)
            return
        end

        developer("^3Change^0", "Setted text to "..new_text.." of the id", id)
    end

    GetDistanceFrom = function(type, id)
        if type:lower() == "marker" or type:lower() == "m" then
            type = "Marker"
        elseif type:lower() == "object" or type:lower() == "o" then
            type = "Object"
        else
            return nil
        end

        local distance = 0.0

        if Utility.Cache[type][id].coords ~= nil then
            return _GetDistanceBetweenCoords(_GetEntityCoords(PlayerPedId()), Utility.Cache[type][id].coords, true)
        else
            return false
        end
    end

    GetCoordOf = function(type, id)
        if type:lower() == "marker" or type:lower() == "m" then
            type = "Marker"
        elseif type:lower() == "object" or type:lower() == "o" then
            type = "Object"
        else
            return nil
        end

        if DoesExist(type, id) then
            return Utility.Cache[type][id].coords
        else
            developer("^1Error^0", "Unable to get the coords of the id", id)
            return false
        end
    end

    DoesExist = function(type, id)
        if type:lower() == "marker" or type:lower() == "m" then
            type = "Marker"
        elseif type:lower() == "object" or type:lower() == "o" then
            type = "Object"
        else
            return nil
        end
        
        if Utility.Cache[type][id] ~= nil then
            return true
        else
            return false
        end
    end

--// Camera //--
    CreateCamera = function(coords, rotation, active, shake)
        local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

        SetCamCoord(cam, coords)

        if rotation ~= nil then
            SetCamRot(cam, rotation.x, rotation.y, rotation.z)
        end

        if shake ~= nil then
            ShakeCam(cam, shake.type or "", shake.amount or 0.0)
        end
        
        if active then
            SetCamActive(cam, true)
            RenderScriptCams(1, 1, 1500, 1, 1)
        end

        return cam
    end

    SwitchBetweenCam = function(old_cam, cam)
        SetCamActiveWithInterp(cam, old_cam, 1500, 1, 1)
        Citizen.Wait(1600)
        DestroyCam(old_cam)
    end 

--// Other // --
    DevMode = function(state, time, format)
        if time == nil then time = true end
        format = format or "%s %s %s"
        
        if state then
            developer = function(action, type, id)
                local _, _, _, hour, minute, second = GetLocalTime()

                if time then
                    if type == nil then
                        print(hour..":"..minute..":"..second.." - "..action)
                    else
                        print(hour..":"..minute..":"..second.." - "..string.format(format, action, type, id))
                    end
                else
                    if type == nil then
                        print(action)
                    else
                        print(string.format(format, action, type, id))
                    end
                end
            end
        else
            developer = function() end
        end
    end

    ReplaceTexture = function(prop, textureName, url, width, height)
        local txd = CreateRuntimeTxd('duiTxd')
        local duiObj = CreateDui(url, width, height)
        local dui = GetDuiHandle(duiObj)
        local tx = CreateRuntimeTextureFromDuiHandle(txd, 'duiTex', dui)
        AddReplaceTexture(prop, textureName, 'duiTxd', 'duiTex')
    end

    printd = function(_table)
        if type(_table) == "table" then
            print(json.encode(_table))
        else
            developer("^1Error", "error dumping table ".._table.." why isnt a table", "")
        end
    end

    local string_gsub = string.gsub
    string.multigsub = function(string, table, new)
        if type(table) then
            for i=1, #table do
                string = string_gsub(string, table[i], new[i])
            end
        else
            for i=1, #table do
                string = string_gsub(string, table[i], new)
            end
        end

        return string
    end

    table.fexist = function(_table, field)
        _table = _table[field]
        if not _table then
            return false
        else
            return true
        end
    end

    local table_remove = table.remove
    table.remove = function(_table, index, onlyfirst)
        if type(index) == "number" then
            table_remove(_table, index)
        elseif type(index) == "string" then
            for k, v in pairs(_table) do
                if k == index then
                    _table[k] = nil -- Can be bugged, probably in future update will be changed with a empty table => {}

                    if onlyfirst then
                        break
                    end
                end
            end
        end
    end

    table.empty = function(_table)
        return next(_table) == nil
    end

    -- I dont think this works, i dont have learned and tested so much metatable of lua
    table.clone = function(_table)
        _table.metatable = {__index = _table}

        local _result = {}
        setmetatable(_result, _table.metatable)

        return _result
    end


--// Dialog //--
    StartDialogue = function(entity, distance, callback)
        local _dialog = {}

        _dialog = {
            entity = entity,
            distance = distance,
            current_question = 1,
            callback = callback
        }

        developer("^2Created^0", "dialogue with entity", entity)
        return {
            Question = function(...) 
                local questions = {...}
                _dialog.questions = questions

                return {
                    Response = function(...)
                        local formatted_text = {}
                        local no_formatted = {}

                        for k1,v1 in pairs({...}) do
                            no_formatted[k1] = {}

                            for k,v in pairs(v1) do
                                if formatted_text[k1] == nil then
                                    formatted_text[k1] = ""
                                end

                                formatted_text[k1] = formatted_text[k1]..k.."~w~ "..v.." | "

                                k = string.multigsub(k, {"%[", "%]"}, {"", ""})
                                k = string.multigsub(k, {"~r~", "~b~", "~g~", "~y~", "~p~", "~o~", "~c~", "~m~", "~u~", "~n~", "~s~", "~w~"}, {"", "","", "","", "","", "","", "","", ""})

                                --print("k = "..k)
                                no_formatted[k1][k] = v
                            end

                            formatted_text[k1] = formatted_text[k1]:sub(1, -3)
                        end

                        _dialog.response = {
                            no_formatted = no_formatted,
                            formatted = formatted_text
                        }

                        _TriggerEvent("Utility:Create", "Dialogue", entity, _dialog)
                        Utility.Cache.Dialogue[entity] = _dialog

                        return {
                            LastQuestion = function(last)
                                Utility.Cache.Dialogue[entity].lastq = last
                                _TriggerEvent("Utility:Edit", "Dialogue", entity, "lastq", last)
                            end
                        }
                    end
                }
            end
        }
    end

    EditDialogue = function(entity)
        if entity ~= nil and IsEntityOnDialogue(entity) then
            return {
                Question = function(...) 
                    local questions = {...}
                    _dialog.questions = questions
        
                    return {
                        Response = function(...)
                            local formatted_text = {}
                            local no_formatted = {}
        
                            for k1,v1 in pairs({...}) do
                                no_formatted[k1] = {}
        
                                for k,v in pairs(v1) do
                                    if formatted_text[k1] == nil then
                                        formatted_text[k1] = ""
                                    end
        
                                    formatted_text[k1] = formatted_text[k1]..k.."~w~ "..v.." | "
        
                                    k = string.multigsub(k, {"%[", "%]"}, {"", ""})
                                    k = string.multigsub(k, {"~r~", "~b~", "~g~", "~y~", "~p~", "~o~", "~c~", "~m~", "~u~", "~n~", "~s~", "~w~"}, {"", "","", "","", "","", "","", "","", ""})
        
                                    --print("k = "..k)
                                    no_formatted[k1][k] = v
                                end
        
                                formatted_text[k1] = formatted_text[k1]:sub(1, -3)
                            end
        
                            _dialog.response = {
                                no_formatted = no_formatted,
                                formatted = formatted_text
                            }
        
                            _TriggerEvent("Utility:Remove", "Dialogue", entity)
                            _TriggerEvent("Utility:Create", "Dialogue", entity, _dialog)
                            Utility.Cache.Dialogue[entity] = _dialog
    
                            return {
                                LastQuestion = function(last)
                                    Utility.Cache.Dialogue[entity].lastq = last
                                    _TriggerEvent("Utility:Edit", "Dialogue", entity, "lastq", last)
                                end
                            }
                        end
                    }
                end
            }
        end
    end

    StopDialogue = function(entity)
        if entity ~= nil and IsEntityOnDialogue(entity) then
            developer("^1Stopping^0", "dialogue", entity)
            if Utility.Cache.Dialogue[entity].lastq ~= nil then
                local a = 0
                local lastq = Utility.Cache.Dialogue[entity].lastq
                local __entity = Utility.Cache.Dialogue[entity].entity
                local entity_coords = GetEntityCoords(__entity) + vector3(0.0, 0.0, 1.0)

                CreateLoop(function()
                    LoopThread(1, 1000, function()
                        entity_coords = GetEntityCoords(__entity) + vector3(0.0, 0.0, 1.0)
                        a = a + 1
                    end)

                    if a == 3 then
                        _break()
                    end
                
                    DrawText3Ds(entity_coords, lastq, nil, nil, true)
                end)
            end

            Utility.Cache.Dialogue[entity] = nil
            _TriggerEvent("Utility:Remove", "Dialogue", entity)
        end
    end

    IsEntityOnDialogue = function(entity)
        return Utility.Cache.Dialogue[entity]
    end
