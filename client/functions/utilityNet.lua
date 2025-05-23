local Entity = Entity

local DebugRendering = false
local DebugInfos = false
local DeletedEntities = {}

local Entities = {}

--#region Local functions
local GetActiveSlices = function()
    local slices = GetSurroundingSlices(currentSlice)
    table.insert(slices, currentSlice)

    return slices
end

local AttachToEntity = function(obj, to, params)
    local attachToObj = nil

    if not params.isUtilityNet then
        attachToObj = NetworkGetEntityFromNetworkId(to)
    else
        -- Ensure that the entity is fully ready
        if UtilityNet.DoesUNetIdExist(to) then
            while not UtilityNet.IsReady(to) do
                Citizen.Wait(1)
            end
        else
                warn("AttachToEntity: trying to attach "..obj.." to "..to.." but the destination netId doesnt exist")
        end

        attachToObj = UtilityNet.GetEntityFromUNetId(to)
    end

    if attachToObj then
        if DebugInfos then
            print("Attaching", obj.." ("..GetEntityArchetypeName(obj)..")", "with", tostring(attachToObj).." ("..GetEntityArchetypeName(attachToObj)..")")
        end
        AttachEntityToEntity(obj, attachToObj, params.bone, params.pos, params.rot, false, params.useSoftPinning, params.collision, true, params.rotationOrder, params.syncRot)
    else
        warn("AttachToEntity: trying to attach "..obj.." to "..to.." but the destination entity doesnt exist")
    end
end

local FindEntity = function(coords, radius, model, uNetId, maxAttempts)
    local attempts = 0
    local obj = 0
        
    while attempts < maxAttempts and not DoesEntityExist(obj) do
        obj = GetClosestObjectOfType(coords.xyz, radius or 5.0, model)
        attempts = attempts + 1
        Citizen.Wait(500)
    end

    if attempts >= maxAttempts and not DoesEntityExist(obj) then
        warn("Failed to find object to replace, model: "..model.." coords: "..coords.." uNetId:"..uNetId)
        return
    end

    return obj
end
--#endregion

--#region Rendering functions
local busyEntities = {}
local SetNetIdBeingBusy = function(uNetId, status)
    busyEntities[uNetId] = status and true or nil
end

local IsNetIdBusy = function(uNetId)
    return busyEntities[uNetId]
end

exports("IsNetIdBusy", IsNetIdBusy)
exports("IsNetIdCreating", IsNetIdBusy)

local UnrenderLocalEntity = function(uNetId)
    local entity = UtilityNet.GetEntityFromUNetId(uNetId)

    if DoesEntityExist(entity) then
        local state = Entity(entity).state

        if not state.preserved then
            TriggerEvent("Utility:Net:OnUnrender", uNetId, entity, GetEntityModel(entity))
        end

        if not DoesEntityExist(entity) then
            if DebugInfos then
                warn("UnrenderLocalEntity: entity with uNetId: "..uNetId.." already unrendered, skipping this call")
            end
            return
        end

        -- Remove state change handler (currently used only for attaching)
        if state.changeHandler then
            UtilityNet.RemoveStateBagChangeHandler(state.changeHandler)
            state.changeHandler = nil
        end

        if state.found then
            if state.door then
                if DoesEntityExist(state.door) then
                    SetEntityVisible(state.door, true)
                    SetEntityCollision(state.door, true, true)
                end
            else
                local model = GetEntityModel(entity)
    
                -- Show map object
                RemoveModelHide(GetEntityCoords(entity), 0.1, model)
            end
        end

        if not state.preserved then
            DeleteEntity(entity)
        end

        state.rendered = false
        EntitiesStates[uNetId] = nil
        TriggerLatentServerEvent("Utility:Net:RemoveStateListener", 5120, uNetId)

        if state.preserved then
            TriggerEvent("Utility:Net:OnUnrender", uNetId, entity, GetEntityModel(entity))
            
            -- Max 5000ms for the entity to be deleted if it was preserved, if it still exists, delete it (this prevents entity leaks)
            Citizen.SetTimeout(5000, function()
                if DoesEntityExist(entity) then
                    warn("UnrenderLocalEntity: entity with uNetId: "..uNetId.." was preserved for more than 5 seconds, deleting it now")
                    DeleteEntity(entity)
                end
            end)
        end
    end

    LocalEntities[uNetId] = nil
end

local RenderLocalEntity = function(uNetId, entityData)
    if IsNetIdBusy(uNetId) then
        if DebugRendering then
            warn("RenderLocalEntity: entity with uNetId: "..uNetId.." is already being created, skipping this call")
        end
        return
    end

    SetNetIdBeingBusy(uNetId, true)

    local obj = 0
    local stateUtility = UtilityNet.State(uNetId)
    local entityData = entityData or UtilityNet.InternalFindFromNetId(uNetId)

    -- Exit if entity data is missing
    if not entityData then
        error("UpdateLocalEntity: entity with uNetId: "..tostring(uNetId).." cant be found")
        return false
    end

    -- Set local variable (for readability)
    local coords = entityData.coords
    local model = entityData.model
    local options = entityData.options

    if options.abstract then
        if options.replace then
            error("RenderLocalEntity: abstract entities can't have the \"replace\" option, uNetId: "..uNetId.." model: "..model)
        end

        if not IsModelValid(model) then
            RegisterArchetypes(function()
                return {
                    {
                        flags = 139296,
                        bbMin = vector3(-0.1, -0.1, -0.1),
                        bbMax = vector3(0.1, 0.1, 0.1),
                        bsCentre = vector3(0.0, 0.0, 0.0),
                        bsRadius = 1.0,
                        name = model,
                        textureDictionary = '',
                        physicsDictionary = '',
                        assetName = model,
                        assetType = 'ASSET_TYPE_DRAWABLE',
                        lodDist = 999,
                        specialAttribute = 0
                    }
                }
            end)
        end
    end

    if not IsModelValid(model) then
        error("RenderLocalEntity: Model "..tostring(model).." is not valid, uNetId: "..uNetId)
    end

    if not options.abstract then
        local start = GetGameTimer()
        while not HasModelLoaded(model) do
            if (GetGameTimer() - start) > 5000 then
                error("RenderLocalEntity: Model "..model.." failed to load, uNetId: "..uNetId)
            end
    
            RequestModel(model)
            Citizen.Wait(1)
        end
    end

    Citizen.CreateThread(function()
        if options.replace then
            local _obj = FindEntity(coords, options.searchDistance, model, uNetId, 5)
    
            -- Skip object creation if not found
            if not DoesEntityExist(_obj) then
                SetNetIdBeingBusy(uNetId, false)
                return
            end
    
            -- Clone object (otherwise it will be deleted when the entity is unrendered and will not respawn properly)
            local coords = GetEntityCoords(_obj)
            local rotation = GetEntityRotation(_obj)
    
            local interior = GetInteriorFromEntity(_obj)
            local room = GetRoomKeyFromEntity(_obj)
    
            obj = CreateObject(model, coords, false, false, options.door)
            SetEntityCoords(obj, coords)
            SetEntityRotation(obj, rotation)
            
            if interior ~= 0 and room ~= 0 then
                ForceRoomForEntity(obj, interior, room)
            end
    
            Entity(obj).state.found = true
    
            -- Hide map object
            local distance = options.door and 1.5 or 0.1

            if options.door and interior ~= 0 then
                Entity(obj).state.door = _obj

                -- Doors inside interiors need to be deleted
                -- If not deleted the game will be recreate them every time the interior is reloaded (player exit and then re-enter)
                -- And so there will be 2 copies of the same door
                SetEntityVisible(_obj, false)
                SetEntityCollision(_obj, false, false)
            else
                CreateModelHideExcludingScriptObjects(coords, distance, model)
            end
        else
            if options.abstract then
                obj = old_CreateObject(model, coords, false, false, options.door)
            else
                obj = CreateObject(model, coords, false, false, options.door)
            end

            SetEntityCoords(obj, coords) -- This is required to ignore the pivot
        end
        
        local state = Entity(obj).state
    
        -- "Disable" the entity
        SetEntityVisible(obj, false)
        SetEntityCollision(obj, false, false)
        
        if options.rotation then
            SetEntityRotation(obj, options.rotation)
        end

        if options.abstract then
            Entity(obj).state.abstract_model = model
        end

        -- Always listen for __attached changes (attach/detach)
        state.changeHandler = UtilityNet.AddStateBagChangeHandler(uNetId, function(key, value)
            -- Exit if entity is no longer valid
            if not DoesEntityExist(obj) then
                UtilityNet.RemoveStateBagChangeHandler(state.changeHandler)
                return
            end

            if key == "__attached" then
                if value then
                    --print("Attach")
                    AttachToEntity(obj, value.object, value.params)
                else
                    --print("Detach")
                    DetachEntity(obj, true, true)
                end
            end
        end)
    
        LocalEntities[uNetId] = {obj=obj, slice=entityData.slice}
    
        -- Fetch initial state
        ServerRequestEntityStates(uNetId)
    
        -- After state has been fetched, attach if needed
        if stateUtility.__attached then
            AttachToEntity(obj, stateUtility.__attached.object, stateUtility.__attached.params)
        end

        -- "Enable" the entity, this is done after the state has been fetched to avoid props doing strange stuffs
        SetEntityVisible(obj, true)
        SetEntityCollision(obj, true, true)
    
        TriggerEvent("Utility:Net:OnRender", uNetId, obj, model)
    
        state.rendered = true
        SetNetIdBeingBusy(uNetId, false)
    end)
end

local CanEntityBeRendered = function(uNetId, entityData, slices)
    -- Default values
    local entityData = entityData or UtilityNet.InternalFindFromNetId(uNetId)

    -- Exit if entity data is missing
    if not entityData then
        return false
    end

    -- Check if entity is within drawing slices (if provided)
    if slices and not table.find(slices, entityData.slice) then
        return false
    end

    local state = UtilityNet.State(uNetId)

    if DeletedEntities[uNetId] then
        return false
    end

    -- Render only if within render distance
    if not state.__attached then
        local coords = GetEntityCoords(PlayerPedId())
        local modelsRenderDistance = GlobalState.ModelsRenderDistance
        local hashmodel = type(entityData.model) == "number" and entityData.model or GetHashKey(entityData.model)
        local renderDistance = modelsRenderDistance[hashmodel] or 50.0

        if #(entityData.coords - coords) > renderDistance then
            return false
        end
    end

    return true
end
--#endregion

StartUtilityNetRenderLoop = function()
    -- Wait for player full load
    local isLoading = false

    while not HasCollisionLoadedAroundEntity(player) or not NetworkIsPlayerActive(PlayerId()) do
        isLoading = true
        Citizen.Wait(100)
    end

    if isLoading then
        Citizen.Wait(1000)
    end

    Citizen.CreateThread(function()
        local lastNEntities = 0 -- Used for managing the speed of the loop based on the number of entities
        local lastSlice = currentSlice
        
        while true do
            DeletedEntities = {}
            local slices = GetActiveSlices()
            local start = GetGameTimer()

            local somethingRendered = false -- If something has been rendered, speed up the whole loop to avoid a ugly effect where everything loads slowly
            local nEntities = 0

            local sleep = (Config.UtilityNetDynamicUpdate - 700) / math.min(20, lastNEntities) -- threshold to allow a little bit of lag and split by number of entities

            -- Render/Unrender near slices entities
            UtilityNet.ForEachEntity(function(v)
                nEntities = nEntities + 1
                if not LocalEntities[v.id] and CanEntityBeRendered(v.id, v) then
                    local obj = UtilityNet.GetEntityFromUNetId(v.id) or 0
                    local state = Entity(obj).state or {}

                    if not state.rendered then
                        somethingRendered = true
                        if DebugRendering then
                            print("RenderLocalEntity", v.id, "Loop")
                        end

                        RenderLocalEntity(v.id, v)                        
                    end
                elseif LocalEntities[v.id] and not CanEntityBeRendered(v.id, v) then
                    somethingRendered = true
                    UnrenderLocalEntity(v.id)
                end

                local outOfTime = (GetGameTimer() - start) > Config.UtilityNetDynamicUpdate
                if not somethingRendered or outOfTime then
                    Citizen.Wait(sleep * (2/3))
                end
            end, slices)

            -- Unrender entities that are out of slice
            -- Run only if the slice has changed (so something can be out of the slice and need to be unrendered)
            if lastSlice ~= currentSlice then
                for netId, data in pairs(LocalEntities) do
                    local entityData = Entities[data.slice][netId]
                
                    if not CanEntityBeRendered(netId, entityData) then
                        UnrenderLocalEntity(netId)
                    end
    
                    Citizen.Wait(sleep * (1/3))
                end

                lastSlice = currentSlice
            end

            if DebugRendering then
                print("end", GetGameTimer() - start)
            end

            lastNEntities = nEntities
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
end

RegisterNetEvent("Utility:Net:RefreshModel", function(uNetId, model)
    local start = GetGameTimer()
    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    if entity and Entities[slice] then
        Entities[slice][uNetId].model = model
    end

    while not LocalEntities[uNetId] and (GetGameTimer() - start < 3000) do
        Citizen.Wait(1)
    end

    if LocalEntities[uNetId] then
        -- Wait for the entity to exist and be rendered (prevent missing model replace on instant model change)
        while not UtilityNet.IsReady(uNetId) or IsNetIdBusy(uNetId) do
            Citizen.Wait(100)
        end
        SetNetIdBeingBusy(uNetId, true)

        -- Preserve the old object so that it does not flash (delete and instantly re-render)
        local oldObj = LocalEntities[uNetId].obj
        local _state = Entity(oldObj).state
        _state.preserved = true

        UnrenderLocalEntity(uNetId)

        -- Tamper with the entity model and render again
        local entityData = UtilityNet.InternalFindFromNetId(uNetId)

        SetNetIdBeingBusy(uNetId, false)
        RenderLocalEntity(uNetId, entityData)

        local time = GetGameTimer()
        -- Wait for the entity to exist and be rendered
        while not UtilityNet.IsReady(uNetId) do
            if GetGameTimer() - time > 3000 then
                break
            end

            Citizen.Wait(1)
        end

        -- Delete the old object after the new one is rendered (so that it does not flash)
        DeleteEntity(oldObj)
    end
end)

RegisterNetEvent("Utility:Net:RefreshCoords", function(uNetId, coords)
    local start = GetGameTimer()
    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    if entity and Entities[slice] then
        Entities[slice][uNetId].coords = coords
        Entities[slice][uNetId].slice = GetSliceFromCoords(coords)
    end

    while not LocalEntities[uNetId] and (GetGameTimer() - start < 3000) do
        Citizen.Wait(1)
    end
    
    if LocalEntities[uNetId] then
        while not UtilityNet.IsReady(uNetId) or IsNetIdBusy(uNetId) do
            Citizen.Wait(100)
        end

        SetNetIdBeingBusy(uNetId, true)
        SetEntityCoords(LocalEntities[uNetId].obj, coords)
        SetNetIdBeingBusy(uNetId, false)
    end
end)

RegisterNetEvent("Utility:Net:RefreshRotation", function(uNetId, rotation)
    local start = GetGameTimer()
    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    if entity and Entities[slice] then
        Entities[slice][uNetId].options.rotation = rotation
    end

    while not LocalEntities[uNetId] and (GetGameTimer() - start < 3000) do
        Citizen.Wait(1)
    end

    if LocalEntities[uNetId] then
        while not UtilityNet.IsReady(uNetId) or IsNetIdBusy(uNetId) do
            Citizen.Wait(100)
        end

        SetNetIdBeingBusy(uNetId, true)
        SetEntityRotation(LocalEntities[uNetId].obj, rotation)
        SetNetIdBeingBusy(uNetId, false)
    end
end)

RegisterNetEvent("Utility:Net:EntityCreated", function(_callId, object)
    local uNetId = object.id
    local slices = GetActiveSlices() 

    if not Entities[object.slice] then
        Entities[object.slice] = {}
    end

    Entities[object.slice][object.id] = object

    if CanEntityBeRendered(uNetId, object, slices) then
        if DebugRendering then
            print("RenderLocalEntity", uNetId, "EntityCreated")
        end

        RenderLocalEntity(uNetId, object)
    end
end)

RegisterNetEvent("Utility:Net:RequestDeletion", function(uNetId)
    if LocalEntities[uNetId] then
        local slice = LocalEntities[uNetId].slice

        DeletedEntities[uNetId] = true
        UnrenderLocalEntity(uNetId)

        if Entities[slice] then
            Entities[slice][uNetId] = nil
        end
    else
        local entityData = UtilityNet.InternalFindFromNetId(uNetId)
        if not entityData then return end

        local slice = GetSliceFromCoords(entityData.coords)

        if Entities[slice] then
            Entities[slice][uNetId] = nil
        end
    end
end)

Citizen.CreateThread(function()
    while DebugRendering do
        DrawText3Ds(GetEntityCoords(PlayerPedId()), "Rendering Requested Entities: ".. #busyEntities)
        Citizen.Wait(1)
    end
end)

Citizen.CreateThread(function()
    RegisterNetEvent("Utility:Net:GetEntities", function(entities)
        Entities = entities
    end)

    TriggerServerEvent("Utility:Net:GetEntities")
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k,v in pairs(LocalEntities) do
            Citizen.CreateThreadNow(function()
                UnrenderLocalEntity(k)
            end)
        end
    end
end)

-- Exports
UtilityNet.GetEntityFromUNetId = function(uNetId)
    return LocalEntities[uNetId]?.obj
end

UtilityNet.GetUNetIdFromEntity = function(entity)
    for k, v in pairs(LocalEntities) do
        if v.obj == entity then
            return k
        end
    end
end

UtilityNet.InternalFindFromNetId = function(uNetId)
    for sliceI, slice in pairs(Entities) do
        if slice[uNetId] then
            return slice[uNetId], sliceI
        end
    end
end

exports("GetEntityFromUNetId", UtilityNet.GetEntityFromUNetId)
exports("GetUNetIdFromEntity", UtilityNet.GetUNetIdFromEntity)
exports("GetRenderedEntities", function() return LocalEntities end)
exports("GetEntities", function(slice)
    if slice then
        return Entities[slice] or {}
    else
        return Entities
    end
end)
exports("InternalFindFromNetId", UtilityNet.InternalFindFromNetId)