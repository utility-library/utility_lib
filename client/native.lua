_G["ESX"], _G["xPlayer"], _G["source"], _G["developer"] = nil, {}, GetPlayerServerId(PlayerId()), function() end

-- Why?, see that https://www.lua.org/gems/sample.pdf#page=3
local _AddTextEntry, _BeginTextCommandDisplayHelp, _EndTextCommandDisplayHelp, _SetNotificationTextEntry, _AddTextComponentSubstringPlayerName, _DrawNotification, _GetEntityCoords, _World3dToScreen2d, _SetTextScale, _SetTextFont, _SetTextEntry, _SetTextCentre, _AddTextComponentString, _DrawText, _DoesEntityExist, _GetDistanceBetweenCoords, _GetPlayerPed, _TriggerEvent, _TriggerServerEvent = AddTextEntry, BeginTextCommandDisplayHelp, EndTextCommandDisplayHelp, SetNotificationTextEntry, AddTextComponentSubstringPlayerName, DrawNotification, GetEntityCoords, World3dToScreen2d, SetTextScale, SetTextFont, SetTextEntry, SetTextCentre, AddTextComponentString, DrawText, DoesEntityExist, GetDistanceBetweenCoords, GetPlayerPed, TriggerEvent, TriggerServerEvent

local resName = GetCurrentResourceName()
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

DevModeStatus = false
UtilityLibLoaded = true

local Utility = {
    Cache = {
        PlayerPedId = PlayerPedId(),
        Marker = {},
        Object = {},
        Dialogue = {},
        Blips = {},
        N3d = {},
        Events = {},

        Guards = {},
        Scenes = {},
        
        SetData = {},
        Frozen = {},
        FlowDetector = {},

        Textures = {},
        --Constant = {},
	Settings = {},
        EntityStack = {},
        Loop = {},
        SliceGroups = {}
    }
}

Citizen.CreateThreadNow(function() -- Load Classes
    if UFAPI then -- if the utility framework API is loaded
        if resName == "utility_lib" then
            _G["Utility"] = Utility
        else
            _G["UtilityLibrary"] = Utility
        end
    else -- the utility framework API is not loaded :(
        _G["Utility"] = Utility
    end
end)

UseDelete = function(boolean)
    Utility.Cache.Settings.UseDelete = boolean
end


--// Emitter //--
    On = function(type, function_id, fake_triggerable)
        RegisterNetEvent("Utility:On:".. (fake_triggerable and "!" or "") ..type)

        local event = AddEventHandler("Utility:On:".. (fake_triggerable and "!" or "") ..type, function_id)
        table.insert(Utility.Cache.Events, event)

        return event
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
    IsControlJustPressed = function(key, _function, description)
        developer("^2Created^0", "key map", key)
        local input = "keyboard"
        key = key:lower()

        if key:find("mouse_") or key:find("iom_wheel") then
            input = "mouse_button"
        elseif key:find("_index") then
            input = "pad_digitalbutton"
        end

        RegisterKeyMapping('utility '..resName..' '..key, (description or ''), input, key)
        table.insert(Utility.Cache.Events, AddEventHandler("Utility:Pressed_"..resName.."_"..key, _function))
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
            
        _AddTextEntry('ButtonNotification'..string.len(msg), msg)
        _BeginTextCommandDisplayHelp('ButtonNotification'..string.len(msg))
        _EndTextCommandDisplayHelp(0, false, true, -1)
    end

    ButtonFor = function(msg, ms)
        local timer = GetGameTimer()
    
        Citizen.CreateThread(function()
            while (GetGameTimer() - timer) < (ms or 5000) do
                ButtonNotification(msg)
                Citizen.Wait(1)
            end
        end)
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
        if coords then
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
                local _, count = string.gsub(factor, "\n", "\n") * 0.025
                if count == nil then count = 0 end

                DrawRect(_x, _y + 0.0125, 0.025 + factor, 0.025 + count, 0, 0, 0, 90)
                end
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

    TaskEasyPlayAnim = function(dict, anim, move, duration)
        if move == nil then move = 51 end
        if duration == nil then duration = -1 end

        TaskPlayAnim(PlayerPedId(), dict, anim, 2.0, 2.0, duration, move, 0)

        if duration > -1 or duration > 0 then
            Citizen.Wait(duration)
        end
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

	    if Utility.Cache.Settings.UseDelete then
            table.insert(Utility.Cache.EntityStack, obj)
        end	

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

    SetPedStatic = function(entity, active)
        FreezeEntityPosition(entity, active)
        SetEntityInvincible(entity, active)
        SetBlockingOfNonTemporaryEvents(entity, active)
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

 -- Loop
    -- Before _break
    StopLoop = function(id)
        Utility.Cache.Loop[id].status = false
    end


    CreateLoop = function(_function, tickTime, dontstart)
        local loopId = RandomId(5)

        Utility.Cache.Loop[loopId] = {
            status = true,
            func = _function,
            tick = tickTime
        }

        if dontstart ~= false then
            Citizen.CreateThread(function()
                while Utility.Cache.Loop[loopId] and Utility.Cache.Loop[loopId].status do
                    _function(loopId)
                    Citizen.Wait(tickTime or 1)
                end
            end)
        end

        return loopId
    end

    PauseLoop = function(loopId, delay)
        Citizen.SetTimeout(delay or 0, function()
            print("Pausing loop "..loopId)
            Utility.Cache.Loop[loopId].status = false
        end)
    end

    ResumeLoop = function(loopId, delay)
        local current = Utility.Cache.Loop[loopId]
        
        Citizen.SetTimeout(delay or 0, function()
            print("Resuming loop "..loopId)
            current.status = true
            Citizen.CreateThread(function()
                while current and current.status do
                    current.func(loopId)
                    Citizen.Wait(current.tick or 1)
                end
            end)
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

    GetNearestValue = function(v, all_v)
        local diff = 100 * 100000000000
        local _i = 0
    
        for i=1, #all_v do
            local c_diff = math.abs(all_v[i] - v)
    
            if (c_diff < diff) then
                diff = c_diff
                n = all_v[i]
                _i = i
            end
        end
    
        return n, diff, _i
    end

--// ESX integration //--
    -- Init
        StartESX = function(eventName, second_job)
            Citizen.CreateThreadNow(function()
                while ESX == nil do
                    TriggerEvent(eventName or 'esx:getSharedObject', function(obj) ESX = obj end)
                    Citizen.Wait(1)
                end
                
                while ESX.GetPlayerData().job == nil do
                    Citizen.Wait(1)
                end
                
                uPlayer = ESX.GetPlayerData()
                xPlayer = uPlayer
                
                if second_job ~= nil then
                    while ESX.GetPlayerData()[second_job] == nil do
                        Citizen.Wait(1)
                    end

                    uPlayer = ESX.GetPlayerData()
                    xPlayer = uPlayer
                end

                if second_job ~= nil then
                    RegisterNetEvent('esx:set'..string.upper(second_job:sub(1,1))..second_job:sub(2), function(job)        
                        uPlayer[second_job] = job
                        xPlayer = uPlayer
                    end)
                end
            
                RegisterNetEvent('esx:setJob', function(job)        
                    uPlayer.job = job
                    xPlayer = uPlayer
                
                    if OnJobUpdate then
                        OnJobUpdate()
                    end
                end)
            end)
        end 
        StartQB = function()
            QBCore = exports['qb-core']:GetCoreObject()
            uPlayer = QBCore.Functions.GetPlayerData()
            Player = uPlayer

            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
                uPlayer = QBCore.Functions.GetPlayerData()
                Player = uPlayer
            end)

            RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
                uPlayer.job = JobInfo
                Player = uPlayer

                if OnJobUpdate then
                    OnJobUpdate()
                end
            end)
        end
        StartFramework = function()
            if GetResourceState("qb-core") ~= "missing" then
                StartQB()

                return true
            elseif GetResourceState("es_extended") ~= "missing" then
                StartESX()

                return true
            end
        end

    -- Job
        GetDataForJob = function(job)
            local job_info = promise:new()

            if GetResourceState("es_extended") == "started" then
                ESX.TriggerServerCallback("Utility:GetJobData", function(worker)
                    job_info:resolve(worker)
                end, job)    
            elseif GetResourceState("qb-core") == "started" then
                QBCore.Functions.TriggerCallback("Utility:GetJobData", function(worker)
                    job_info:resolve(worker)
                end, job)    
            end

            job_info = Citizen.Await(job_info)
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
	        NetworkRequestControlOfEntity(entityToGrab)
            while not NetworkHasControlOfEntity(entityToGrab) do Citizen.Wait(1) end
		
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

    IsInRadius = function(coords1, coords2, radius, debugSphere)
        local distance = #(coords1-coords2)

        if debugSphere then
            DrawSphere(coords2, radius, 255, 0, 0, 0.5)
        end
        return distance < radius
    end

    IsNearCoords = function(coords, radius, debugSphere)
        local distance = #(GetEntityCoords(PlayerPedId())-coords)

        if debugSphere then
            DrawSphere(coords, radius, 255, 0, 0, 0.5)
        end
        return distance < radius
    end
    
    GenerateRandomCoords = function(coords, radius, heading)
        local x = coords.x + math.random(-radius, radius)
        local y = coords.y + math.random(-radius, radius)
        local _, z = GetGroundZFor_3dCoord(x,y,200.0,0)

        if heading then
            return vector3(x,y,z), math.random(0.0, 360.0)
        end

        return vector3(x,y,z)
    end

--// Managing data (like table, but more easy to use) //--

    SetFor = function(id, property, value)
        -- If id dont already exist register it for store data
        if Utility.Cache["SetData"][id] == nil then
            Utility.Cache["SetData"][id] = {}
        end

        if type(property) == "table" then -- Table
            for k,v in pairs(property) do
                if type(v) == "function" then
                    developer("^2Setting^0", "data", "("..id..") ["..k.." = "..tostring(v).."] {table}")
                else
                    developer("^2Setting^0", "data", "("..id..") ["..k.." = "..json.encode(v).."] {table}")
                end
                Utility.Cache["SetData"][id][k] = v
            end
        else -- Single
            if type(value) == "function" then
                developer("^2Setting^0", "data", "("..id..") ["..property.." = "..tostring(value).."] {single}")
            else
                developer("^2Setting^0", "data", "("..id..") ["..property.." = "..json.encode(value).."] {single}")
            end
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

--// Slices //--
    function GetSliceCoordsFromCoords(coord)
        --                       coord + max / sliceRadius
        return vector2(math.floor((coord.x + 8192) / 100), math.floor((coord.y + 8192) / 100))
    end

    function GetSliceFromCoords(pos)
        local slice = GetSliceCoordsFromCoords(pos)
        --               (x * 2^2 + y) = id
        local id = (slice.x * math.pow(2, 2)) + slice.y

        return id
    end

    function GetEntitySlice(ped)
        return GetSliceFromCoords(GetEntityCoords(ped))
    end
    function GetPlayerSlice(player)
        local ped = GetPlayerPed(player)

        return GetSliceFromCoords(GetEntityCoords(ped))
    end
    function GetSelfSlice()
        local ped = PlayerPedId()

        return GetSliceFromCoords(GetEntityCoords(ped))
    end
    function IsOnScreen(coords)
        local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
                        
        return onScreen
    end
    function SliceUsed(slice)
        return Utility.Cache.SliceGroups[slice] or false
    end
    function SetSliceUsed(slice, value)
        Utility.Cache.SliceGroups[slice] = value
    end


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
            if type(coords) ~= "vector3" then
                developer("^1Error^0","You can use only vector3 for coords!",id)
                return
            end

            id = string.gsub(id, "{r}", RandomId())

            developer("^2Created^0","Marker",id)

            local _marker = {
                render_distance = render_distance,
                interaction_distance = interaction_distance,
                coords = coords,
                slice = (options and options.slice == "ignore") and -1 or tostring(GetSliceFromCoords(coords))
            }

            -- Options

            if type(options) == "table" then
                if options.rgb ~= nil then -- Marker
                    _marker.type = 1
                    _marker.rgb = options.rgb
                elseif options.text ~= nil then -- 3d Text
                    _marker.type = 0
                    _marker.text = options.text
                else
                    _marker.type = 1
                    _marker.rgb = {options[1], options[2], options[3]}
                end
                
                if options.type ~= nil and type(options.type) == "number" then _marker._type = options.type end
                if options.direction ~= nil and type(options.direction) == "vector3" then _marker._direction = options.direction end
                if options.rotation ~= nil and type(options.rotation) == "vector3" then _marker._rot = options.rotation end
                if options.scale ~= nil and type(options.scale) == "vector3" then _marker._scale = options.scale end
                if options.alpha ~= nil and type(options.alpha) == "number" then _marker.alpha = options.alpha end
                if options.animation ~= nil and type(options.animation) == "boolean" then _marker.anim = options.animation end
                if options.job ~= nil then _marker.job = options.job end

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

        SetMarker = function(id, _type, key, value)
            if (type(value) ~= _type) and (value ~= nil) then
                developer("^1Error^0", key.." can be only a ".._type, "[Marker]")
                return 
            end
            
            if DoesExist("marker", id) then
                Utility.Cache.Marker[id][key] = value
                _TriggerEvent("Utility:Edit", "Marker", id, key, value)
            else
                developer("^1Error^0", "Unable to edit the marker as it does not exist", id)
            end
        end

        SetMarkerType = function(id, _type)
            SetMarker(id, "number", "_type", _type)
        end

        SetMarkerDirection = function(id, direction)
            SetMarker(id, "vector3", "_direction", direction)
        end

        SetMarkerRotation = function(id, rot)
            SetMarker(id, "vector3", "_rot", rot)
        end

        SetMarkerScale = function(id, scale)
            SetMarker(id, "vector3", "_scale", scale)
        end

        SetMarkerColor = function(id, rgb)
            SetMarker(id, "table", "rgb", rgb)
        end

        ---
        SetMarkerCoords = function(id, coords)
            SetMarker(id, "string", "slice", tostring(GetSliceFromCoords(coords)))
            SetMarker(id, "vector3", "coords", coords)
        end

        SetMarkerRenderDistance = function(id, render_distance)
            SetMarker(id, "number", "render_distance", render_distance)
        end

        SetMarkerInteractionDistance = function(id, interaction_distance)
            SetMarker(id, "number", "interaction_distance", interaction_distance)
        end
        ---

        SetMarkerAlpha = function(id, alpha)
            SetMarker(id, "number", "alpha", alpha)
        end

        SetMarkerAnimation = function(id, active)
            SetMarker(id, "boolean", "anim", active)
        end

        SetMarkerDrawOnEntity = function(id, active)
            SetMarker(id, "boolean", "draw_entity", active)
        end

        SetMarkerNotify = function(id, text)
            if type(text) == "string" then
                text = string.multigsub(text, {"{A}","{B}", "{C}", "{D}", "{E}", "{F}", "{G}", "{H}", "{L}", "{M}", "{N}", "{O}", "{P}", "{Q}", "{R}", "{S}", "{T}", "{U}", "{V}", "{W}", "{X}", "{Y}", "{Z}"}, {"~INPUT_VEH_FLY_YAW_LEFT~", "~INPUT_SPECIAL_ABILITY_SECONDARY~", "~INPUT_LOOK_BEHIND~", "~INPUT_MOVE_LR~", "~INPUT_CONTEXT~", "~INPUT_ARREST~", "~INPUT_DETONATE~", "~INPUT_VEH_ROOF~", "~INPUT_CELLPHONE_CAMERA_FOCUS_LOCK~", "~INPUT_INTERACTION_MENU~", "~INPUT_REPLAY_ENDPOINT~" , "~INPUT_FRONTEND_PAUSE~", "~INPUT_FRONTEND_LB~", "~INPUT_RELOAD~", "~INPUT_MOVE_DOWN_ONLY~", "~INPUT_MP_TEXT_CHAT_ALL~", "~INPUT_REPLAY_SCREENSHOT~", "~INPUT_NEXT_CAMERA~", "~INPUT_MOVE_UP_ONLY~", "~INPUT_VEH_HOTWIRE_LEFT~", "~INPUT_VEH_DUCK~", "~INPUT_MP_TEXT_CHAT_TEAM~", "~INPUT_HUD_SPECIAL~"})
            end

            SetMarker(id, "string", "notify", notify)
        end

        -- 3dText
        Set3dText = function(id, text)
            SetMarker(id, "string", "text", text)
        end

        Set3dTextScale = function(id, scale)
            SetMarker(id, "number", "_scale", scale)
        end

        Set3dTextDrawRect = function(id, active)
            SetMarker(id, "boolean", "rect", active)
        end

        Set3dTextFont = function(id, font)
            SetMarker(id, "number", "font", font)
        end

    DeleteMarker = function(id)
        if not DoesExist("m", id) then
            Citizen.Wait(100)
            return
        else
            developer("^1Deleted^0","Marker",id)
            Utility.Cache.Marker[id] = nil
            _TriggerEvent("Utility:Remove", "Marker", id)
            ClearAllHelpMessages()
        end
    end

    -- Object
    CreateiObject = function(id, model, pos, heading, interaction_distance, network, job)
        developer("^2Created^0 Object "..id.." ("..model..")")

        local obj
        if network ~= nil then
            obj = CreateObject(GetHashKey(model), pos.x,pos.y,pos.z, network, false, false) or nil
        else
            obj = CreateObject(GetHashKey(model), pos.x,pos.y,pos.z, true, false, false) or nil
        end

        SetEntityHeading(obj, heading)
        SetEntityAsMissionEntity(obj, true, true)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(hash)

        _object = {
            obj = obj,
            coords = pos,
            interaction_distance = interaction_distance or 3.0,
            slice = tostring(GetSliceFromCoords(pos)),
            job = job
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

    CreateJobBlip = function(name, coords, job, sprite, colour, scale)
        _TriggerEvent("Utility:Create", "Blips", math.random(10000, 99999), {
            name = name,
            coords = coords,
            job = job,
            sprite = sprite,
            colour = colour,
            scale = scale or 1.0
        })
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
            RenderScriptCams(1, 1, 1500)
        end

        return cam
    end

    SwitchBetweenCam = function(old_cam, cam, duration)
        SetCamActiveWithInterp(cam, old_cam, duration or 1500, 1, 1)
        Citizen.Wait(duration or 1500)
        DestroyCam(old_cam)
    end 

--// Other // --
    DevMode = function(state, time, format)
        DevModeStatus = true

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
        local txName = prop..":"..textureName..":" -- prop:textureName 
        local txId = txName..":"..url -- txName:url (prop:textureName:url)

        if not Utility.Cache.Textures[txId] then -- If texture with same prop, texture name and url does not exist we create it (to prevent 2 totally same dui)
            local txd = CreateRuntimeTxd(txName..'duiTxd')
            local duiObj = CreateDui(url, width, height)
            local dui = GetDuiHandle(duiObj)
            
            CreateRuntimeTextureFromDuiHandle(txd, txName..'duiTex', dui)

            Utility.Cache.Textures[txId] = true
        end

        AddReplaceTexture(prop, textureName, txName.."duiTxd", txName.."duiTex")
    end

    printd = function(_table, advanced)
        if advanced then
            local printTable_cache = {}
 
            local function sub_printTable(t, indent)
                if (printTable_cache[tostring(t)]) then
                    print(indent.."*"..tostring(t))
                else
                    printTable_cache[tostring(t)] = true
                    if (type(t) == "table") then
                        for pos,val in pairs(t) do
                            if (type(val) == "table") then
                                print(indent.."["..pos.."] => "..tostring(t).. " {" )
                                    sub_printTable(val, indent..string.rep(" ", string.len(pos)+8))
                                print(indent..string.rep(" ", string.len(pos)+6 ).."}")
                            elseif (type(val) == "string") then
                                print(indent.."["..pos.."] => \"" .. val .. "\"")
                            else
                                print(indent.."["..pos.."] => "..tostring(val))
                            end
                        end
                    else
                        print(indent..tostring(t))
                    end
                end
            end
         
            if (type(_table) == "table") then
                print(tostring(_table).." {")
                sub_printTable(_table, "  ")
                print("}")
            else
                developer("^1Error^0", "error dumping table ".._table.." why isnt a table", "")
            end
        else
            if type(_table) == "table" then
                print(json.encode(_table, {indent = true}))
            else
                developer("^1Error^0", "error dumping table ".._table.." why isnt a table", "")
            end
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
            return table_remove(_table, index)
        elseif type(index) == "string" then
            for k, v in pairs(_table) do
                if k == index then
                    _table[k] = nil -- Can be bugged, probably in future update will be changed with a empty table => {}

                    if onlyfirst then
                        return k
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
    local function DialogueTable(entity, dialog, editing)
        return {
            Question = function(...) 
                dialog.questions = {...}

                return DialogueTable(entity, dialog, editing)
            end,

            Response = function(...)
                local responses = {...}
                
                -- If a table is passed with the answers and not all the answers separated use that
                if type(responses[1]) == "table" then
                    responses = responses[1]
                end

                local formatted_text = {}
                local no_formatted = {}

                for k1,v1 in pairs(responses) do
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

                dialog.response = {
                    no_formatted = no_formatted,
                    formatted = formatted_text
                }

                if editing then
                    _TriggerEvent("Utility:Remove", "Dialogue", entity)
                    _TriggerEvent("Utility:Create", "Dialogue", entity, dialog)
                else
                    _TriggerEvent("Utility:Create", "Dialogue", entity, dialog)
                end
                Utility.Cache.Dialogue[entity] = dialog

                return DialogueTable(entity, dialog, editing)
            end,

            LastQuestion = function(last)
                Utility.Cache.Dialogue[entity].lastQuestion = last
                _TriggerEvent("Utility:Edit", "Dialogue", entity, "lastQuestion", last)

                return DialogueTable(entity, dialog, editing)
            end
        }
    end

    StartDialogue = function(entity, distance, callback, stopWhenTalking)
        local dialog = {
            entity = entity,
            distance = distance,
            curQuestion = 1,
            callback = callback,
            stopWhenTalking = stopWhenTalking,
            slice = tostring(GetEntitySlice(entity))
        }

        developer("^2Created^0", "dialogue with entity", entity)
        return DialogueTable(entity, dialog)
    end

    EditDialogue = function(entity)
        if entity ~= nil and IsEntityOnDialogue(entity) then
            return DialogueTable(entity, Utility.Cache.Dialogue[entity], true)
        end
    end

    StopDialogue = function(entity)
        if entity ~= nil and IsEntityOnDialogue(entity) then
            developer("^1Stopping^0", "dialogue", entity)

            -- Set the current question as if it were the last one
            local questions = Utility.Cache.Dialogue[entity].questions[1]
            _TriggerEvent("Utility:Edit", "Dialogue", entity, "curQuestion", #questions)
        end
    end

    IsEntityOnDialogue = function(entity)
        return Utility.Cache.Dialogue[entity]
    end

    RegisterNetEvent("Utility:DeleteDialogue", function(entity)
        Utility.Cache.Dialogue[entity] = nil
    end)

--// N3d //--
    function GetScaleformsStatus()
        local activeList = {}
        local inactiveList = {}
        for i = 1, 10 do
            local scaleformName = "utility_lib_" .. i
            if IsScaleformTaken(scaleformName) then
                table.insert(activeList, {name = scaleformName, data = Utility.Cache.N3d[scaleformName]})
            else
                table.insert(inactiveList, {name = scaleformName, data = {txd = false, show = false, rotation = {}}})
            end
        end
        return activeList, inactiveList
    end

    function IsScaleformTaken(scaleformName)
        return Utility.Cache.N3d[scaleformName] ~= nil
    end

    local old_RequestScaleformMovie = RequestScaleformMovie
    local function RequestScaleformMovie(scaleform)-- idk why but sometimes give error
        print(scaleform)

        local status, retval = pcall(old_RequestScaleformMovie, scaleform)

        while not status do
            status, retval = pcall(old_RequestScaleformMovie, scaleform)
            Citizen.Wait(1)
        end

        return retval
    end

    local function LoadScaleform(N3dHandle, scaleformName)
        local scaleformHandle = RequestScaleformMovie(scaleformName) -- idk why but sometimes give error

        -- Wait till it has loaded
        local startTimer = GetGameTimer()

        while not HasScaleformMovieLoaded(scaleformHandle) and (GetGameTimer() - startTimer) < 4000 do
            Citizen.Wait(0)
        end

        if (GetGameTimer() - startTimer) > 4000 then
            developer("^1Error^0", "After 4000 ms to load the scaleform the scaleform has not loaded yet, try again or check that it has started correctly!", "")
            return
        end

        -- Save the handle in the table
        Utility.Cache.N3d[N3dHandle].scaleform = scaleformHandle
        _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "scaleform", scaleformHandle)
    end

    local function StartupDui(N3dHandle, url, width, height)
        local txd = CreateRuntimeTxd('txd'..N3dHandle) -- Create texture dictionary

        Utility.Cache.N3d[N3dHandle].dui = CreateDui(url, width, height) -- Create Dui with the url
        _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "dui", Utility.Cache.N3d[N3dHandle].dui)

        while not IsDuiAvailable(Utility.Cache.N3d[N3dHandle].dui) do
            Citizen.Wait(1)
        end

        local dui = GetDuiHandle(Utility.Cache.N3d[N3dHandle].dui) -- Getting dui handle

        CreateRuntimeTextureFromDuiHandle(txd, 'txn'..N3dHandle, dui) -- Applying the txd on the dui

        if Utility.Cache.N3d[N3dHandle].scaleform ~= nil and not Utility.Cache.N3d[N3dHandle].txd then
            BeginScaleformMovieMethod(Utility.Cache.N3d[N3dHandle].scaleform, 'SET_TEXTURE')

            ScaleformMovieMethodAddParamTextureNameString('txd'..N3dHandle) -- txd
            ScaleformMovieMethodAddParamTextureNameString('txn'..N3dHandle) -- txn

            ScaleformMovieMethodAddParamInt(0) -- x
            ScaleformMovieMethodAddParamInt(0) -- y
            ScaleformMovieMethodAddParamInt(width)
            ScaleformMovieMethodAddParamInt(height)

            EndScaleformMovieMethod()
            Utility.Cache.N3d[N3dHandle].txd = true
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "txd", true)
        end
    end

    -- Class and handle
    function CreateNui3d(scaleformName, url)
        local N3dHandle = tostring(math.random(0, 9999))

        local _N3d = {
            txd = false,
            show = false,
            rotation = {}
        }

        Utility.Cache.N3d[N3dHandle] = _N3d
        _TriggerEvent("Utility:Create", "N3d", N3dHandle, _N3d) -- Sync the table in the utility_lib

        -- Auto load the scaleform
        LoadScaleform(N3dHandle, scaleformName)

        if url ~= nil then
            developer("^2Starting^0", N3dHandle.." with url ".."nui://"..GetCurrentResourceName().."/"..url.." sf "..scaleformName, "")
            StartupDui(N3dHandle, "nui://"..GetCurrentResourceName().."/"..url, 1920, 1080)
        end


        -- Class to return
        local N3d_Class = {}
        N3d_Class.__index = N3d_Class

        N3d_Class.init = function(self, url, width, height)
            StartupDui(N3dHandle, "nui://"..GetCurrentResourceName().."/"..url, width or 1920, height or 1080)
        end
	
        N3d_Class.datas = function(self)
            return Utility.Cache.N3d[N3dHandle]
        end

        N3d_Class.scale = function(self, scale)
            Utility.Cache.N3d[N3dHandle].advanced_scale = scale
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "advanced_scale", scale)
        end

        N3d_Class.rotation = function(self, rotation, syncedwithplayer)
            Utility.Cache.N3d[N3dHandle].rotation.rotation = rotation
            Utility.Cache.N3d[N3dHandle].rotation.syncedwithplayer = syncedwithplayer

            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "rotation", {
                rotation = rotation,
                syncedwithplayer = syncedwithplayer
            })
        end

        N3d_Class.destroy = function(self)
            if Utility.Cache.N3d[N3dHandle].dui ~= nil then
                DestroyDui(Utility.Cache.N3d[N3dHandle].dui)
                SetScaleformMovieAsNoLongerNeeded(Utility.Cache.N3d[N3dHandle].scaleform)
                Utility.Cache.N3d[N3dHandle] = nil
                _TriggerEvent("Utility:Remove", "N3d", N3dHandle)

            end
        end

        N3d_Class.started = function()
            return Utility.Cache.N3d[N3dHandle].dui ~= nil
        end

        N3d_Class.show = function(self, coords, scale)
            Utility.Cache.N3d[N3dHandle].coords = coords
            Utility.Cache.N3d[N3dHandle].scale = scale or 0.1
            Utility.Cache.N3d[N3dHandle].show = true

            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "coords", coords)
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "scale", scale or 0.1)
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "show", true)
        end

        N3d_Class.visible = function()
            return Utility.Cache.N3d[N3dHandle].show
        end

        N3d_Class.hide = function()
            Utility.Cache.N3d[N3dHandle].show = false
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "show", false)
        end

        N3d_Class.attach = function(self, entity, offset)
            Utility.Cache.N3d[N3dHandle].attach = {
                entity = entity,
                offset = offset or vector3(0.0, 0.0, 0.0)
            }
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "attach", {
                entity = entity,
                offset = offset or vector3(0.0, 0.0, 0.0)
            })
        end

        N3d_Class.detach = function(self, atcoords)
            if atcoords then
                Utility.Cache.N3d[N3dHandle].coords = GetEntityCoords(Utility.Cache.N3d[N3dHandle].attach.entity)
                _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "coords", Utility.Cache.N3d[N3dHandle].coords)
            end
            Utility.Cache.N3d[N3dHandle].attach = nil
            _TriggerEvent("Utility:Edit", "N3d", N3dHandle, "attach", nil)
        end

        N3d_Class.object = function()
            return Utility.Cache.N3d[N3dHandle].dui
        end

        N3d_Class.msg = function(self, msg)
            if self:started() then
                SendDuiMessage(self:object(), json.encode(msg))
            end
        end

        return setmetatable({}, N3d_Class), N3dHandle
    end

    AddEventHandler("onResourceStop", function(_resName)
        if _resName == resName then
            for i=1, #Utility.Cache.Events do
                RemoveEventHandler(Utility.Cache.Events[i])
            end

            for handle,data in pairs(Utility.Cache.N3d) do
                if data.dui ~= nil then
                      DestroyDui(data.dui)
                      _TriggerEvent("Utility:Remove", "N3d", handle)
                end
            end

	    if Utility.Cache.Settings.UseDelete then
                for i=1, #Utility.Cache.EntityStack do
                    local ent = Utility.Cache.EntityStack[i]
                    NetworkRequestControlOfEntity(ent)
                    if DoesEntityExist(ent) then
                        DeleteEntity(ent)
                    end
                end
            end
        end
    end)

--// Physics [Test] //--
    CalculateNewAxisPosition = function(coords, space, axis, time)
        local speed = space * time

        return coords[axis] + speed
    end

    TranslateUniformRectilinearMotion = function(obj, destination, duration)
        local coords = GetEntityCoords(obj)
        local timer = GetNetworkTimeAccurate()
        local space = {
            x = destination.x - coords.x,
            y = destination.y - coords.y,
            z = destination.z - coords.z,
        }

        --print(json.encode(space))

        while #(coords - destination) > 0.05 do -- while not at destination
            --print("Distance: "..#(coords - destination))

            Citizen.Wait(0) -- wait 1 tick
            coords = GetEntityCoords(obj)
            local timeAccurate = GetNetworkTimeAccurate()

            if timer ~= 0 and (timeAccurate - timer) ~= 0 then -- if it elapsed some time from the last call
                local deltaTime = (timeAccurate - timer)
                local time = deltaTime / duration
                local newCoords = {x = 0.0, y = 0.0, z = 0.0}

                for i=1, 3 do
                    local axis = (i==1 and "x") or (i==2 and "y") or (i==3 and "z")
                    local newAxis = CalculateNewAxisPosition(coords, space, axis, time)

                    newCoords[axis] = newAxis
                end

                --print("Set coords: ", json.encode(newCoords))
                SetEntityCoords(obj, newCoords.x, newCoords.y, newCoords.z)
            end

            timer = timeAccurate
        end
    end

--// Heists //--
    -- Scene
        CreateScene = function(coords, rot, holdLastFrame, looped, animSpeed)
            local scene = NetworkCreateSynchronisedScene(coords, rot, 2, holdLastFrame or false, looped or false, 1065353216, 0, animSpeed or 1.3)
            Utility.Cache.Scenes[scene] = {
                coords = coords,
                rotation = rot,
                players = {},
                entities = {},
                dicts = {},
            }
            
            return scene
        end

        AddEntityToScene = function(entity, scene, dict, name, speed, speedMultiplier, flag)
            if not DoesEntityExist(tonumber(entity)) then
                local model = entity
                local coords = GetEntityCoords(PlayerPedId())
                entity = CreateObject(entity, coords + vector3(0,0, -4.0), true)
                SetEntityCollision(entity, false, true)

                Utility.Cache.Scenes[scene].entities[model] = entity -- if the entity was created by the scene then it will have automatic handling, otherwise you will have to delete it yourself manually
            end

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(1)
            end

            developer("^3Scenes^0", "Adding object", entity, "to scene", scene, "[", dict, name, "]", "")
            NetworkAddEntityToSynchronisedScene(entity, scene, dict, name, speed or 4.0, speedMultiplier or -8.0, flag or 1)
            table.insert(Utility.Cache.Scenes[scene].dicts, dict)
        end

        AddPlayerToScene = function(player, scene, dict, name, ...)
            Citizen.InvokeNative(0x144da052257ae7d8, true) -- synchronize the scene with any player that is in the scene

            local ped = DoesEntityExist(player) and player or GetPlayerPed(player) -- (player id) or (player ped id) are accepted
            AddPedToScene(ped, scene, dict, name, ...)

            Utility.Cache.Scenes[scene].players[ped] = {
                dict = dict,
                name = name
            }
        end

        AddPedToScene = function(ped, scene, dict, name, blendIn, blendOut, duration, flag)
            if not DoesEntityExist(ped) then
                local model = ped
                ped = CreatePed(ped, vector3(0,0,0), 0.0, true)
                
                Utility.Cache.Scenes[scene].entities[model] = ped -- if the entity was created by the scene then it will have automatic handling, otherwise you will have to delete it yourself manually
            end

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(1)
            end

            developer("^3Scenes^0", "Adding ped", ped, "to scene", scene, "[", dict, name, "]", "")
            NetworkAddPedToSynchronisedScene(ped, scene, dict, name, blendIn or 1.5, blendOut or -4.0, duration or 1, flag or 16, 0, 0)
            table.insert(Utility.Cache.Scenes[scene].dicts, dict)
        end

        GoNearInitialOffset = function(player, coords, rot, dict, name)
            -- Taken from https://github.com/root-cause/v-decompiled-scripts/blob/master/fm_mission_controller.c line 752898
            local ped = DoesEntityExist(player) and player or GetPlayerPed(player) -- (player id) or (player ped id) are accepted
            local heading = rot and rot.z or GetEntityHeading(ped)
            
            --Citizen.Wait(5000)

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(1)
            end

            local pos = GetAnimInitialOffsetPosition(dict, name, coords, 0.0, 0.0, heading, 0.0, 2)
            local rot = GetAnimInitialOffsetRotation(dict, name, coords, 0.0, 0.0, heading, 0.0, 2)
            
            RemoveAnimDict(dict)

            TaskGoStraightToCoord(ped, pos, 0.6, -1, rot.z, 0.4)
            --TaskFollowNavMeshToCoord(ped, pos, 0.6, -1, 0.1, true)

            -- Wait until it is close to the start zone
            local startCheckingDistance = GetGameTimer()

            --DebugCoords(coords)
            --DebugCoords(pos)

            while (#(GetEntityCoords(ped) - pos) > 0.3) do
                Citizen.Wait(1)
            end

            --TaskAchieveHeading(ped, rot.z, 1000)
            --Citizen.Wait(1000)

            -- Wait until he has stopped
            while GetEntitySpeed(ped) > 0.2 do
                Citizen.Wait(50)
            end

            -- Let's add a break just in case (weird bugs can happen without it)
            --Citizen.Wait(1000)
        end

        StartScene = function(scene, goNearInitialOffset)
            local curScene = Utility.Cache.Scenes[scene]

            if goNearInitialOffset then
                for ped, v in pairs(curScene.players) do
                    GoNearInitialOffset(ped, curScene.coords, curScene.rotation, v.dict, v.name)
                end
            end

            NetworkStartSynchronisedScene(scene)
        end

        StopScene = function(scene)
            developer("^3Scenes^0", "Stop scene", scene)
            NetworkStopSynchronisedScene(scene)

            local curScene = Utility.Cache.Scenes[scene]

            -- Delete create entities
            for model, entity in pairs(curScene.entities) do
                developer("^3Scenes^0", "Deleting entity", entity)
                DeleteEntity(entity)
            end

            -- Unload anim dicts
            for i=1, #curScene.dicts do
                RemoveAnimDict(curScene.dicts[i])
            end
        end

        GetSceneEntity = function(scene, model)
            if model then
                return Utility.Cache.Scenes[scene].entities[model]
            else
                return Utility.Cache.Scenes[scene].entities
            end
        end

    -- Thermal Charge
        local StartPlantThermalChargeScene = function(door, coords)
            local ped = PlayerPedId()
            local rot = GetEntityRotation(door)
            
            --DebugCoords(coords)
            --GoNearInitialOffset(ped, coords, "anim@heists@ornate_bank@thermal_charge", "thermal_charge")

            local scene = CreateScene(coords, rot)
            AddPlayerToScene(ped, scene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge")
            AddEntityToScene("hei_p_m_bag_var22_arm_s", scene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge")
            StartScene(scene, true)

            return scene
        end

        local FindDoorLockCoords = function(door)
            local size = GetEntitySize(door)

            if doorHash == `hei_v_ilev_bk_safegate_pris` then
                --                                                                 SafePedCoords
                return GetOffsetFromEntityInWorldCoords(door, -(size.x - 0.1), -0.05, 0.0)
            else
                --                                                                SafePedCoords
                return GetOffsetFromEntityInWorldCoords(door, (size.x - 0.1), -0.05, 0.0)
            end
        end

        local PullOutThermalCharge = function(ped, coords)
            local thermal = CreateObject("hei_prop_heist_thermite", coords - vector3(0, 0, 5), true)

            SetEntityCollision(thermal, false, false)
            AttachEntityToEntity(thermal, ped, GetPedBoneIndex(ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)

            return thermal
        end

        local PlantThermalCharge = function(thermal)
            DetachEntity(thermal, true, true)
        end

        local StartThermalChargeEffect = function(thermal)
            return StartParticleFxOnNetworkEntity("scr_ornate_heist", "scr_heist_ornate_thermal_burn", thermal, vector3(0.0, 1.0, -0.1), vector3(0.0, 0.0, 0.0), 1.0)
        end

        local CoverEyesFromThermalCharge = function(ped)
            TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 1.5, 1.0, -1, 51, 1, 0, 0, 0)
        end

        local GetMoltenModel = function(door)
            local model = GetEntityModel(door)

            if model == `hei_v_ilev_bk_gate_pris` then
                return "hei_v_ilev_bk_gate_molten"

            elseif model == `hei_v_ilev_bk_gate2_pris` then
                return "hei_v_ilev_bk_gate2_molten"
                
            elseif model == `hei_v_ilev_bk_safegate_pris` then
                return "hei_v_ilev_bk_safegate_molten"
            end
        end

        local ChangeDoorModel = function(door)
            local moltenModel = GetMoltenModel(door)

            if moltenModel then
                SetEntityModel(door, moltenModel)
            end
        end

        local StopThermalChargeEffect = function(ped, thermal)  
            DeleteObject(thermal)
            TaskPlayAnim(ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_exit", 1.0, 8.0, 1000, 51, 1, 0, 0, 0)

            Citizen.Wait(1000)
            ClearPedTasks(ped)
        end

        BreakDoorWithThermalCharge = function(door, bagComponent, duration)
            local ped = PlayerPedId()
            local doorLock = FindDoorLockCoords(door)

            local scene = StartPlantThermalChargeScene(door, doorLock)

            SetPedComponentVariation(ped, 5, 0, 0, 0) -- Remove real bag from player
            Citizen.Wait(1000)
            local thermal = PullOutThermalCharge(ped, doorLock)

            Citizen.Wait(3000)
            PlantThermalCharge(thermal)

            --print("start effect")
            Citizen.Wait(1000)
            local effect = StartThermalChargeEffect(thermal)
            
            --print("stop scene")
            StopScene(scene)
            SetPedComponentVariation(ped, 5, bagComponent or 45, 0, 0) -- Reset real bag to player

            developer("^3Scenes^0", "Cover eyes", "")
            --print("cover eyes")
            CoverEyesFromThermalCharge(ped)
            Citizen.Wait(1000)
            ChangeDoorModel(door)
            developer("^3Scenes^0", "Wait "..(duration or 3000), "")
            Citizen.Wait(duration or 3000)
            StopThermalChargeEffect(ped, thermal)
        end

    -- Trolly
        -- Create
        local GetTrollyModel = function(type)
            if type == "cash" then
                return "hei_prop_hei_cash_trolly_01"
            elseif type == "gold" then
                return "ch_prop_gold_trolly_01a"
            elseif type == "diamond" then
                return "ch_prop_diamond_trolly_01a"
            end
        end
        
        local GenerateTrollyId = function(type)
            return "utility_heist:"..type.."_trolly:"..math.random(1, 10000) -- example: utility_heist:cash_trolly:3910
        end
        
        CreateTrolly = function(type, coords, giveCash, notify, minSpeed, maxSpeed)
            local obj = nil
            local id = GenerateTrollyId(type) -- Pseudo random id
        
            -- Object creation
            if type == "cash" then
                obj = CreateObject("hei_prop_hei_cash_trolly_01", coords, true)
            elseif type == "gold" then
                obj = CreateObject("ch_prop_gold_trolly_01a", coords, true)
            elseif type == "diamond" then
                obj = CreateObject("ch_prop_diamond_trolly_01a", coords, true)
            end
            
            PlaceObjectOnGroundProperly(obj)
        
            -- Marker and data creation
            CreateMarker(id, coords, 0.0, 2.0, {notify = notify or "Press {E} to begin looting the trolly"})
            SetFor(id, "minSpeed", minSpeed)
            SetFor(id, "maxSpeed", maxSpeed)
            SetFor(id, "giveCash", giveCash)

            local eventHandler = nil
            eventHandler = On("marker", function(_id)
                if _id == id then
                    local type = id:match("utility_heist:(%w+)_trolly")
        
                    local coords = GetEntityCoords(PlayerPedId())
                    local model = GetTrollyModel(type)
                    local trollyObj = GetClosestObjectOfType(coords, 3.0, GetHashKey(model))
                        
                    DeleteMarker(id)
        
                    if trollyObj > 0 then
                        LootTrolly(id, type, trollyObj)
                        RemoveEventHandler(eventHandler)
                    end
                end
            end)

            return id, obj
        end

        -- Loot
        local GetEmptyTrollyModel = function(type)
            if type == "cash" then
                return "hei_prop_hei_cash_trolly_03"
            else
                return "hei_prop_hei_cash_trolly_03"
                --return "ch_prop_gold_trolly_empty"
            end
        end
        
        local GetTrollyCashProp = function(type)
            if type == "cash" then
                return "hei_prop_heist_cash_pile"
            elseif type == "gold" then
                return "ch_prop_gold_bar_01a"
            elseif type == "diamond" then
                return "ch_prop_vault_dimaondbox_01a"
            end
        end
        
        local CollectCashProp = function(id, giveCash)
            PlaySoundFrontend(-1, "LOCAL_PLYR_CASH_COUNTER_INCREASE", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", true)
            giveCash() -- Give cash function
        end
        
        local CreateCashProp = function(id, model, giveCash)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local cashProp = CreateObject(model, coords, true)
        
            FreezeEntityPosition(cashProp, true)
            SetEntityInvincible(cashProp, true)
            SetEntityNoCollisionEntity(cashProp, ped)
            SetEntityVisible(cashProp, false, false)
            AttachEntityToEntity(cashProp, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
            DisableCamCollisionForEntity(cashProp)
        
            Utility.Cache.LootingTrolly = true
        
            Citizen.CreateThread(function()
                local eventCashAppear = `CASH_APPEAR`
                local eventReleaseCashDestroy = `RELEASE_CASH_DESTROY`
        
                while Utility.Cache.LootingTrolly do            
                    if HasAnimEventFired(ped, eventCashAppear) then
                        SetEntityVisible(cashProp, true, false) -- Set entity visible
                    end
                    if HasAnimEventFired(ped, eventReleaseCashDestroy) then
                        if IsEntityVisible(cashProp) then -- Set Entity invisible
                            SetEntityVisible(cashProp, false, false)
        
                            CollectCashProp(id, giveCash)
                        end
                    end
        
                    Citizen.Wait(1)
                end
                DeleteObject(cashProp)
            end)
        end
        
        local StartLootIntroScene = function(bag, trolly)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(trolly)
            local rot = GetEntityRotation(trolly)
        
            local scene = CreateScene(coords, rot)
            AddPlayerToScene(ped, scene, "anim@heists@ornate_bank@grab_cash", "intro")
            AddEntityToScene(bag, scene, "anim@heists@ornate_bank@grab_cash", "bag_intro")
            StartScene(scene, true)
        
            return scene
        end
        
        local StartPlayerInteractionGrabLoop = function(grabScene, min, max)
            local lscene = NetworkGetLocalSceneFromNetworkId(grabScene)
            local speed = min
            local finished = false
        
            -- Every mouse click add 0.1 to the speed
            IsControlJustPressed("MOUSE_LEFT", function()
                if speed <= max then
                    speed = speed + 0.1
                end
            end)
        
            -- Wait that the scene start
            while not IsSynchronizedSceneRunning(lscene) do
                lscene = NetworkGetLocalSceneFromNetworkId(grabScene)
                Citizen.Wait(1)
            end

            Citizen.CreateThread(function()
                AddTextEntry('PersistentButtonNotification', "Repeatedly press ~INPUT_SCRIPT_RDOWN~ to grab faster")
                BeginTextCommandDisplayHelp('PersistentButtonNotification')
                EndTextCommandDisplayHelp(0, true, true, -1)
            end)
        
            -- If the scene is still running, remove 0.1 every 300ms
            while GetSynchronizedScenePhase(lscene) < 0.99 do
                lscene = NetworkGetLocalSceneFromNetworkId(grabScene)
        
                if speed > min then
                    speed = speed - 0.1
                end
                
                SetSynchronizedSceneRate(lscene, speed)
                Citizen.Wait(300)
            end
        
            ClearAllHelpMessages()
            finished = true
            --print("Finished grabbing money")
        end
        
        local StartLootGrabScene = function(bag, trolly)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(trolly)
            local rot = GetEntityRotation(trolly)
        
            local scene = CreateScene(coords, rot)
            AddPlayerToScene(ped, scene, "anim@heists@ornate_bank@grab_cash", "grab")
            AddEntityToScene(bag, scene, "anim@heists@ornate_bank@grab_cash", "bag_grab")
            AddEntityToScene(trolly, scene, "anim@heists@ornate_bank@grab_cash", "cart_cash_dissapear")
            StartScene(scene)
        
            return scene
        end
        local StartLootExitScene = function(bag, trolly)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(trolly)
            local rot = GetEntityRotation(trolly)
        
            local scene = CreateScene(coords, rot)
            AddPlayerToScene(ped, scene, "anim@heists@ornate_bank@grab_cash", "exit")
            AddEntityToScene(bag, scene, "anim@heists@ornate_bank@grab_cash", "bag_exit")
            StartScene(scene)
        
            return scene
        end
        
        LootTrolly = function(id, type, trolly)
            local ped = PlayerPedId()
            local cashPropModel = GetTrollyCashProp(type)
            local emptyTrolly = GetEmptyTrollyModel(type)
            local options = GetFrom(id)

        
            if IsEntityPlayingAnim(trolly, "anim@heists@ornate_bank@grab_cash", "cart_cash_dissapear", 3) then
                return
            end
        
            while not NetworkHasControlOfEntity(trolly) do
                Citizen.Wait(1)
                NetworkRequestControlOfEntity(trolly)
            end
        
            local bagObj = CreateObject("hei_p_m_bag_var22_arm_s", vector3(0.0, 0.0, 0.0), true)
            SetEntityCollision(bagObj, false, true)
        
            -- Intro
                local introScene = StartLootIntroScene(bagObj, trolly)
                developer("^3Scenes^0", "Started Intro scene", "")
        
                SetPedComponentVariation(ped, 5, 0, 0, 0)
                Citizen.Wait(1500)
        
                developer("^3Scenes^0", "Create cash prop", "")
                CreateCashProp(id, cashPropModel, options.giveCash)
                developer("^3Scenes^0", "Starting grabbing scene", "")
        
            -- Grab Scene
                local grabScene = StartLootGrabScene(bagObj, trolly)
                developer("^3Scenes^0", "Started grab scene", "")
                StartPlayerInteractionGrabLoop(grabScene, options.minSpeed or 1.0, options.maxSpeed or 1.6)
        
                CollectCashProp(id, options.giveCash) -- last cash prop isnt in the animation events
                
                SetEntityModel(trolly, emptyTrolly)
        
            -- Exit
                Utility.Cache.LootingTrolly = false
        
                local exitScene = StartLootExitScene(bagObj, trolly)
                developer("^3Scenes^0", "Started exit scene", trolly)
                Citizen.Wait(1800)
        
                DeleteEntity(bagObj)
        
                StopScene(introScene)
                StopScene(grabScene)
                StopScene(exitScene)
                developer("^3Scenes^0", "Stopped all scenes", trolly)
        
                SetPedComponentVariation(ped, 5, 45, 0, 0)
        end

    -- Guards
        local GuardAlertnessLoopRunning = false
        local SpottedByGuards = false

        Citizen.CreateThread(function()
            AddRelationshipGroup("GUARDS")
            SetPedRelationshipGroupHash(PlayerPedId(), `PLAYER`)
        end)

        local CheckIfCanAttack = function(player, v)
            if HasEntityClearLosToEntity(v, player, 27) and GetPedTaskCombatTarget(v) ~= player then
                TaskCombatHatedTargetsAroundPed(v, 10.0, 0)
                SetRelationshipBetweenGroups(5, `GUARDS`, `PLAYER`)
                SetPedToInformRespectedFriends(v, 30.0, 3)
                SetPedAiBlipHasCone(v, false)

                if not SpottedByGuards then
                    SpottedByGuards = true
                    TriggerEvent("Utility:On:spotted", v)
                end
            end
        end

        local TryToStartGuardAlertnessLoop = function()
            if not GuardAlertnessLoopRunning then
                GuardAlertnessLoopRunning = true

                Citizen.CreateThread(function()
                    while GuardAlertnessLoopRunning do        
                        if next(Utility.Cache.Guards) then -- if there's any guard
                            local player = PlayerPedId()
                            local coords = GetEntityCoords(player)
                            local inStealth = GetPedStealthMovement(player)
                            local distance = inStealth and 30.0 or 60.0 -- (if stealth then 30.0 else 60.0)
                            local running = IsPedRunning(player)
                    
                            for k,v in ipairs(Utility.Cache.Guards) do
                                local guardCoords = GetEntityCoords(v)
        
                                -- Check if is dying
                                if IsPedDeadOrDying(v) then
                                    SetPedCanRagdoll(v, true)
                                    SetEntityAsNoLongerNeeded(v)
        
                                    table.remove(Utility.Cache.Guards, k)
                                else
                                    -- Check if to near
                                    if #(coords - guardCoords) < (running and 8.0 or 5.0) then -- if to near
                                        CheckIfCanAttack(player, v)
                                    end
                                    
                                    -- Check if can be viewed
                                    if #(coords - guardCoords) < distance then -- if is in the possible cone
                                        local guardMaxCoords = GetOffsetFromEntityInWorldCoords(v, 0.0, distance, 0.0)
                        
                                        if IsEntityInAngledArea(PlayerPedId(), guardCoords, guardMaxCoords, 50.0) then
                                            CheckIfCanAttack(player, v)
                                        end
                                    end
    
                                    if IsPedShooting(v) or IsPedInCombat(v) then
                                        SetPedToInformRespectedFriends(v, 30.0, 3)
                                        SetPedAiBlipHasCone(v, false)

                                        if not SpottedByGuards then
                                            SpottedByGuards = true
                                            TriggerEvent("Utility:On:spotted", v)
                                        end
                                    end
                                end
    
                            end
                        else
                            SpottedByGuards = false
                            GuardAlertnessLoopRunning = false
                        end
                
                        Citizen.Wait(500)
                    end
                end)
            end
        end
        
        SetGuardDifficulty = function(guard, difficulty)
            local armour, alertness, accuracy, range, ability = 0, 0, 0, 0, 0

            if difficulty == "easy" then
                alertness = 1
                accuracy = 40
                range = 0
                ability = 0
            elseif difficulty == "medium" then
                alertness = 2
                accuracy = 60
                range = 2
                ability = 1
            elseif difficulty == "hard" then
                alertness = 3
                accuracy = 80
                range = 2
                ability = 2
                armour = 50
            elseif difficulty == "veryhard" then
                alertness = 3
                accuracy = 95
                range = 2
                ability = 2
                armour = 100
            end
            
            SetPedArmour(ped, armour)
            SetPedAlertness(ped, alertness)
            SetPedAccuracy(ped, accuracy)
            SetPedCombatRange(ped, range)
            SetPedCombatAbility(ped, ability)
        end

        CreateGuard = function(model, coords, heading, difficulty, guardRoute)
            local ped, netId = CreatePed(model, coords, heading, true)
            SetPedAiBlip(ped, true)
            SetPedAiBlipForcedOn(ped, true)
            SetPedAiBlipHasCone(ped, true)
        
            SetPedRandomComponentVariation(ped, 0)
            SetPedRandomProps(ped)
            SetPedCanRagdoll(ped, false)
        
            --SetEntityAsMissionEntity(ped)
        
            SetPedCombatMovement(ped, 2)
            SetGuardDifficulty(ped, difficulty)
            
            SetPedCombatAttributes(ped, 46, true)
            SetPedFleeAttributes(ped, 0, false)

            --GiveWeaponToPed(ped, `WEAPON_PISTOL`, 255, false, true)
            SetPedRelationshipGroupHash(ped, `GUARDS`)
        
            if guardRoute then
                TaskPatrol(ped, "miss_"..guardRoute, 1, 0, 1)
            end
        
            table.insert(Utility.Cache.Guards, ped)

            TryToStartGuardAlertnessLoop()
            return ped
        end
        
        CreateGuardRoute = function(name, positions, manualRouteLink)
            OpenPatrolRoute("miss_"..name)
            local debugLines = {}
        
            for i=1, #positions do
                local position = positions[i]
        
                if type(position) == "vector3" then
                    AddPatrolRouteNode(i, "StandGuard", position, position, 5000)
                else
                    AddPatrolRouteNode(i, position.anim or "StandGuard", position.destination, position.viewat or position.destination, position.wait or 5000)
                end
        
                if manualRouteLink then
                    manualRouteLink(i-1, i)
                else
                    if i == #positions then
                        AddPatrolRouteLink(i, 1) -- close the circle
                        table.insert(debugLines, {positions[i], positions[1]})
                    end
        
                    if i > 1 then
                        AddPatrolRouteLink(i-1, i)
                        table.insert(debugLines, {positions[i-1], positions[i]})
                    end
                end
            end
        
            ClosePatrolRoute()
            CreatePatrolRoute()
        
            if DevModeStatus then
                CreateLoop(function(loopId)
                    for i=1, #debugLines do
                        DrawLine(debugLines[i][1], debugLines[i][2], 255, 0, 0, 255)
                    end
                end)
            end
        end
        
        SetGuardRoute = function(guard, route)
            TaskPatrol(guard, "miss_"..route, 1, 0, 1)
        end

--// Other //--
    SetEntityModel = function(entity, model)
        TriggerServerEvent("Utility:SwapModel", GetEntityCoords(entity), GetEntityModel(entity), type(model) == "string" and GetHashKey(model) or model)
    end

    StopCurrentTaskAndWatchPlayer = function(ped, duration)
        local coords1 = GetEntityCoords(ped, true)
        local coords2 = GetEntityCoords(PlayerPedId(), true)
        local heading = GetHeadingFromVector_2d(coords2.x - coords1.x, coords2.y - coords1.y)

        TaskAchieveHeading(ped, heading, duration or 2000)
    end

    StartParticleFxOnNetworkEntity = function(ptxAsset, name, obj, ...)
        TriggerServerEvent("Utility:StartParticleFxOnNetworkEntity", ptxAsset, name, ObjToNet(obj), ...)
    end

    GetEntitySize = function(entity)
        local model = GetEntityModel(entity)
        local min, max = GetModelDimensions(model)
        return max - min
    end

    DebugCoords = function(coords)
        CreateLoop(function(loopId)
            DrawText3Ds(coords, "V")
        end)
    end

    GetDirectionFromVectors = function(vec, vec2)
        return vec - vec2
    end

    RotationToDirection = function(rotation)
    
        local adjustedRotation = 
        { 
            x = (math.pi / 180) * rotation.x, 
            y = (math.pi / 180) * rotation.y, 
            z = (math.pi / 180) * rotation.z 
        }
        local direction = 
        {
            x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
            y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
            z = math.sin(adjustedRotation.x)
        }
        return vector3(direction.x, direction.y, direction.z)
    end

    TranslateZAnimated = function(obj, z, stepduration)
        local coords = GetEntityCoords(obj)
        local isNegative = z < 0
    
        for i=1, math.abs(z)*100 do
            local newZ = isNegative and (coords.z - i/100) or (coords.z + i/100)
    
            SetEntityCoords(obj, coords.x, coords.y, newZ)
            Citizen.Wait(stepduration)
        end
    end

    SetVehicleWheelsPowered = function(veh, active)
        for i=0, GetVehicleNumberOfWheels(veh) - 1 do
            SetVehicleWheelIsPowered(veh, i, active)
        end
    end


    -- NEW --
    CreateMissionText = function(msg, duration)            
        SetTextEntry_2("STRING")
        AddTextComponentString(msg)
        DrawSubtitleTimed(duration and math.floor(duration) or 60000 * 240, 1) -- 4h

        return {
            delete = function()
                ClearPrints()
            end
        }
    end

    WaitNear = function(coords)
        local player = PlayerPedId()

        while #(GetEntityCoords(player) - coords) > 10 do 
            Citizen.Wait(100) 
        end
    end

    apairs = function(t, f)
        local a = {}
        local i = 0
    
        for k in pairs(t) do table.insert(a, k) end
        table.sort(a, f)
        
        local iter = function() -- iterator function
            i = i + 1
            if a[i] == nil then 
                return nil
            else 
                return a[i], t[a[i]]
            end
        end
    
        return iter
    end

    FindInTable = function(table, text)
        for i=1, #table do
            if table[i] == text then
                return i
            end
        end
    
        return nil
    end
    GetRandom = function(table)
        local random = math.random(1, #table)
        return table[random]
    end

    Probability = function(number) 
        return math.random(1, 100) <= number
    end
    
    AddPercentage = function(number, percentage)
        return number + (number * percentage / 100)
    end
    
    RemovePercentage = function(number, percentage)
        return number - (number * percentage / 100)
    end

    InTimeRange = function(min, max)
        local hour = nil

        if utc then
            local _, _, _, _hour = GetUtcTime()
            hour = _hour
        else
            hour = GetClockHours()
        end

        if max > min then
            if hour >= min and hour <= max then
                return true
            end 
        else
            -- to fix the times from one day to another, for example from 22 to 3
            if hour <= max or hour >= min then
                return false
            end
        end
    end

    local syncedStateBag = {
        __index = function(self, k)
            if k == "set" then
                return function(self, k, v, replicate) -- set method
                    if replicate then
                        if not self.state[k] then -- if dont exist
                            TriggerServerEvent("Utility:CreateStateBag", NetworkGetNetworkIdFromEntity(self.entity), k, v)
                        else -- if exist
                            self.state:set(k, v, replicate)
                        end
                    else
                        self.state:set(k, v, replicate)
                    end
                end
            else
                return self.state[k] -- return state from the statebag
            end
        end,
        __newindex = function(self, k, v)
            self:set(k, v, self.replicate) -- use the wrapped set method
        end
    }

    _G.old_Entity = Entity
    Entity = function(entity, replicate)
        local ent = old_Entity(entity)
        return {
            state = setmetatable({entity = entity, state = ent.state, replicate = replicate}, syncedStateBag)
        }
    end

    -- Physics [Test]
    CalculateNewAxisPosition = function(coords, space, axis, time)
        local speed = space * time

        return coords[axis] + speed
    end

    TranslateUniformRectilinearMotion = function(obj, destination, duration)
        local coords = GetEntityCoords(obj)
        local timer = GetNetworkTimeAccurate()
        local space = {
            x = destination.x - coords.x,
            y = destination.y - coords.y,
            z = destination.z - coords.z,
        }

        print(json.encode(space))

        while #(coords - destination) > 0.05 do -- while not at destination
            print("Distance: "..#(coords - destination))

            Citizen.Wait(0) -- wait 1 tick
            coords = GetEntityCoords(obj)
            local timeAccurate = GetNetworkTimeAccurate()

            if timer ~= 0 and (timeAccurate - timer) ~= 0 then -- if it elapsed some time from the last call
                local elapsedLastCall = (timeAccurate - timer)
                local time = elapsedLastCall / duration
                local newCoords = {x = 0.0, y = 0.0, z = 0.0}

                for i=1, 3 do
                    local axis = (i==1 and "x") or (i==2 and "y") or (i==3 and "z")
                    local newAxis = CalculateNewAxisPosition(coords, space, axis, time)

                    newCoords[axis] = newAxis
                end

                print("Set coords: ", json.encode(newCoords))
                SetEntityCoords(obj, newCoords.x, newCoords.y, newCoords.z)
            end

            timer = timeAccurate
        end
    end
