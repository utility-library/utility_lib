local Entity = Entity

local DebugRendering = false
local DebugInfos = false

-- Used to prevent that the main loop tries to render an entity that has/his been/being deleted 
-- (the for each entity itearate over the old entities until next cycle and so will try to render a deleted entity)
local DeletedEntities = {}

local EntitiesPromise = nil
local Entities = {}

--#region Local functions
local GetActiveSlices = function()
    local slices = GetSurroundingSlices(currentSlice)
    table.insert(slices, currentSlice)

    return slices
end

local CollectInactiveSlicesEntities = function(slices)
    slices = slices or GetActiveSlices()

    for slice, data in pairs(Entities) do
        local keep = table.find(slices, slice)

        if not keep then
            Entities[slice] = nil
        end
    end
end

local AttachToEntity = function(obj, to, params)
    local attachToObj = nil

    if not params.isUtilityNet then
        attachToObj = NetworkGetEntityFromNetworkId(to)
    else
        -- Ensure that the entity is fully ready
        local start = GetGameTimer()
        while not UtilityNet.IsReady(to) do
            if (GetGameTimer() - start) > 3000 then
                error("AttachToEntity: Entity existance check timed out for uNetId "..tostring(to))
                return
            end
            Citizen.Wait(1)
        end

        attachToObj = UtilityNet.GetEntityFromUNetId(to)
    end

    if attachToObj then
        if DebugInfos then
            print("Attaching", obj.." ("..GetEntityArchetypeName(obj)..")", "with", tostring(attachToObj).." ("..GetEntityArchetypeName(attachToObj)..")")
        end

        if params.boneServer and params.boneServer > 0 then
            if IsEntityAPed(attachToObj) then
                params.bone = GetPedBoneIndex(attachToObj, params.boneServer)
            else
                params.bone = GetEntityBoneIndexByName(attachToObj, params.boneServer)
            end

            if params.bone == 0 then
                local entityType = IsEntityAPed(attachToObj) and "ped" or "entity"
                warn("AttachToEntity: boneServer "..tostring(params.boneServer).." not found on "..entityType.." "..tostring(attachToObj).." ("..GetEntityArchetypeName(attachToObj)..")")
            end
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

local UnrenderLocalEntity = function(uNetId, keepStates)
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

        if not keepStates then
            EntitiesStates[uNetId] = nil
            TriggerLatentServerEvent("Utility:Net:RemoveStateListener", 5120, uNetId)
        end

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

                LocalEntities[uNetId]?.attached = value
            end
        end)
        
        -- Fetch initial state if needed
        if not DoesEntityStateExist(uNetId) then
            --print("REQUEUST STATE", uNetId)
            ServerRequestEntityStates(uNetId)
        else
            --print("WAIT STATE", uNetId)
            EnsureStateLoaded(uNetId)
            --print("STATE LOADED", uNetId)
        end

        LocalEntities[uNetId] = {obj=obj, renderTime = GetGameTimer(), slice=entityData.slice, createdBy = entityData.createdBy, attached = stateUtility.__attached}

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

-- When rendering multiple entities at once, this function requests the state of all entities in one go, 
-- reducing the number of network requests and overhead on the server. This results in improved performance. 
-- This method is more efficient than calling 'RenderLocalEntity' for each entity individually, 
-- as it requires fewer requests and reduces the servers load.
local RenderLocalEntities = function(entities)
    if #entities > 0 then
        local ids = {}

        for _, entityData in pairs(entities) do
            ids[#ids + 1] = entityData.id
        end

        ServerRequestEntitiesStates(ids)
    
        for _, entityData in pairs(entities) do
            RenderLocalEntity(entityData.id, entityData)
        end
    end
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

    if DeletedEntities[uNetId] then
        return false
    end

    -- Render only if within render distance
    local coords = GetEntityCoords(PlayerPedId())
    local attached = LocalEntities[uNetId]?.attached
    local modelsRenderDistance = GlobalState.ModelsRenderDistance
    local hashmodel = type(entityData.model) == "number" and entityData.model or GetHashKey(entityData.model)
    local renderDistance = modelsRenderDistance[hashmodel] or 50.0
    
    local entityCoords = entityData.coords

    if attached then
        if attached.params.isUtilityNet then
            if LocalEntities[uNetId] then
                entityCoords = GetEntityCoords(LocalEntities[uNetId].obj)
            else
                if UtilityNet.DoesUNetIdExist(attached.object) then
                    entityCoords = UtilityNet.GetEntityCoords(attached.object)
                end
            end
        else
            -- Networked entity which this entity is attached to does not exist
            -- Just keep rendered, the server will detach the entity properly in the next slice update
            if not NetworkDoesNetworkIdExist(attached.object) then 
                return true
            end

            -- Calculate distance from networked entity
            local entity = NetworkGetEntityFromNetworkId(attached.object)

            entityCoords = GetEntityCoords(entity)

            local _slice = GetSliceFromCoords(entityCoords)
        end
    end

    return #(entityCoords - coords) < renderDistance
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

            local nEntities = 0

            local sleep = (Config.UtilityNetDynamicUpdate - 700) / math.min(20, lastNEntities) -- threshold to allow a little bit of lag and split by number of entities

            CollectInactiveSlicesEntities(slices)

            -- Render/Unrender near slices entities
            local needRender = {}

            UtilityNet.ForEachEntity(function(v)
                nEntities = nEntities + 1
                local canRender = CanEntityBeRendered(v.id, v)

                if not LocalEntities[v.id] and canRender then
                    local obj = UtilityNet.GetEntityFromUNetId(v.id) or 0
                    local state = Entity(obj).state or {}

                    if not state.rendered and not IsNetIdBusy(v.id) then
                        if DebugRendering then
                            print("RenderLocalEntity", v.id, "Loop")
                        end

                        needRender[#needRender + 1] = v
                    end
                elseif LocalEntities[v.id] and not canRender then
                    if DebugRendering then
                        print("UnrenderLocalEntity", v.id, "Loop")
                    end

                    UnrenderLocalEntity(v.id)
                end

                local outOfTime = (GetGameTimer() - start) > Config.UtilityNetDynamicUpdate
                if outOfTime then
                    Citizen.Wait(sleep * (2/3))
                end
            end, slices)

            RenderLocalEntities(needRender)

            -- Unrender entities that are out of slice
            -- Run only if the slice has changed (so something can be out of the slice and need to be unrendered)
            if lastSlice ~= currentSlice then
                for netId, data in pairs(LocalEntities) do
                    local entityData = Entities[data.slice] and Entities[data.slice][netId]
                    local age = (GetGameTimer() - data.renderTime)

                    if (age > 1000) and (not entityData or not CanEntityBeRendered(netId, entityData)) then
                        if DebugRendering then
                            print("UnrenderLocalEntity", netId, "Slice change")
                        end
                        UnrenderLocalEntity(netId)
                    end
                end

                lastSlice = currentSlice
            end

            if DebugRendering then
                print("RENDER LOOP FINISHED", (GetGameTimer() - start))
            end

            lastNEntities = nEntities
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
end

RegisterNetEvent("Utility:Net:RefreshModel", function(uNetId, model)
    local timeout = 3000
    local start = GetGameTimer()
    local entity, slice = nil

    while not entity or not slice do
        entity, slice = UtilityNet.InternalFindFromNetId(uNetId)
        
        if (GetGameTimer() - start) > timeout then
            error("UtilityNet:RefreshModel: Entity existance check timed out for uNetId "..tostring(uNetId))
            break
        end

        Citizen.Wait(1)
    end

    if entity and Entities[slice] then
        Entities[slice][uNetId].model = model
    else
        error(
            "Utility:Net:RefreshModel: Entity not found for uNetId " .. tostring(uNetId) ..
            " setting model " .. tostring(model) ..
            " entity: " .. tostring(entity) ..
            ", slice: " .. tostring(slice) ..
            ", doesExist? " .. tostring(UtilityNet.DoesUNetIdExist(uNetId))
        )
    end

    start = GetGameTimer()
    while not LocalEntities[uNetId] and (GetGameTimer() - start < timeout) do
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

        UnrenderLocalEntity(uNetId, true)

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

RegisterNetEvent("Utility:Net:RefreshCoords", function(uNetId, coords, skipPositionUpdate)
    local start = GetGameTimer()
    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    if entity and Entities[slice] then
        local newSlice = GetSliceFromCoords(coords) 

        if newSlice ~= slice then
            local entity = Entities[slice][uNetId]
            Entities[slice][uNetId] = nil
            
            if not Entities[newSlice] then
                Entities[newSlice] = {}
            end

            Entities[newSlice][uNetId] = entity
            
            slice = newSlice
        end

        Entities[slice][uNetId].coords = coords
        Entities[slice][uNetId].slice = newSlice
    end

    if not skipPositionUpdate then
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
    end
end)

RegisterNetEvent("Utility:Net:RefreshRotation", function(uNetId, rotation, skipRotationUpdate)
    local start = GetGameTimer()
    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    if entity and Entities[slice] then
        Entities[slice][uNetId].options.rotation = rotation
    end

    if not skipRotationUpdate then
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
    end
end)

RegisterNetEvent("Utility:Net:EntityCreated", function(_callId, object)
    -- If slice is loaded add to it
    if Entities[object.slice] then
        Entities[object.slice][object.id] = object
    end
end)

RegisterNetEvent("Utility:Net:RequestDeletion", function(uNetId, model, coords, rotation)
    local slice = GetSliceFromCoords(coords)

    if Entities[slice] then
        Entities[slice][uNetId] = nil
    end

    if LocalEntities[uNetId] then
        DeletedEntities[uNetId] = true
        UnrenderLocalEntity(uNetId)
    end
end)

Citizen.CreateThread(function()
    while DebugRendering do
        DrawText3Ds(GetEntityCoords(PlayerPedId()), "Rendering Requested Entities: ".. #busyEntities)
        Citizen.Wait(1)
    end
end)

-- Inverse of EncodeEntitiesForClient
-- encoded schema:
-- {
--   groups = { createdBy = { "creatorA", "creatorB", ... } },
--   entities = {
--     { id, model, createdByIndex, {x,y,z}, options },
--     ...
--   }
-- }
--
-- Returns:
-- {
--   [tostring(slice)] = {
--     {
--       id = <number>,
--       model = <number>,
--       createdBy = <string>,
--       coords = { x = <num>, y = <num>, z = <num> },
--       options = <table>,
--       slice = <slice>
--     }, ...
--   }
-- }

local DecodeEntitiesFromServer = function(encoded)
    assert(type(encoded) == "table", "encoded must be a table")
    assert(encoded.groups and encoded.groups.createdBy, "encoded.groups.createdBy missing")
    assert(encoded.entities and type(encoded.entities) == "table", "encoded.entities missing")

    local createdByList = encoded.groups.createdBy
    local entities = {}

    for slice, enc_entities in pairs(encoded.entities) do
        entities[slice] = {}

        for _, enc_entity in pairs(enc_entities) do
            -- layout: { id, model, createdByIndex, {x,y,z}, options }
            local id = enc_entity[1]
            local model = enc_entity[2]
            local cbindex = enc_entity[3]
            local pos = enc_entity[4]
            local opts = enc_entity[5]

            if id == -1 or model == -1 or cbindex == -1 then
                warn("DecodeEntitiesFromServer: Got invalid entity: id="..id..", model="..model..", cbindex="..cbindex)
            end

            if not createdByList[cbindex] then
                warn("DecodeEntitiesFromServer: Something has gone wrong, no creator found for index "..cbindex..", list: "..json.encode(createdByList))
            end

            local ent = {
                id = id,
                model = model,
                coords = vec3(pos[1] or 0.0, pos[2] or 0.0, pos[3] or 0.0),
                slice = slice,
                options = opts,
                createdBy = createdByList[cbindex], -- restore string from index
            }

            entities[slice][id] = ent
        end
    end

    return entities
end

RegisterNetEvent("Utility:Net:GetEntities", function(entities)
    if entities and not table.empty(entities) then
        entities = DecodeEntitiesFromServer(entities)
    
        -- Update cached slices
        for slice, sentities in pairs(entities) do
            --print("Caching entities for slice", slice)
            Entities[slice] = sentities
        end
    end

    EntitiesPromise:resolve(true)
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k,v in pairs(LocalEntities) do
            Citizen.CreateThreadNow(function()
                DeletedEntities[k] = true
                UnrenderLocalEntity(k)
            end)
        end
    else
        for k,v in pairs(LocalEntities) do
            if v.createdBy == resource then
                if DebugRendering then
                    print("Unrendering deleted entity", k)
                end

                Citizen.CreateThreadNow(function()
                    DeletedEntities[k] = true
                    UnrenderLocalEntity(k)
                end)
            end
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

UtilityNet.GetuNetIdCreator = function(uNetId)
    return LocalEntities[uNetId]?.createdBy
end

UtilityNet.GetEntityCreator = function(entity)
    return UtilityNet.GetuNetIdCreator(UtilityNet.GetUNetIdFromEntity(entity))
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
exports("GetuNetIdCreator", UtilityNet.GetuNetIdCreator)
exports("GetEntityCreator", UtilityNet.GetEntityCreator)

exports("GetRenderedEntities", function() return LocalEntities end)
exports("GetEntities", function(slices)
    if slices then
        if type(slices) == "table" then
            -- Check already loaded entities first, if found remove from the list of slices to request
            for i = #slices, 1, -1 do
                local slice = slices[i]

                if Entities[slice] then
                    table.remove(slices, i)
                end
            end
    
            EntitiesPromise = promise.new()
            
            -- We still need to request some slices?
            if #slices > 0 then
                TriggerServerEvent("Utility:Net:GetEntities", slices)
            else
                EntitiesPromise:resolve(true)
            end
    
            Citizen.Await(EntitiesPromise)

            -- Ensure cache exist also for empty slices
            if #slices > 0 then
                for _, slice in ipairs(slices) do
                    Entities[slice] = Entities[slice] or {}
                end
            end

            return Entities
        else
            return Entities[slice] or {}
        end
    else
        return Entities
    end
end)

exports("GetServerEntities", function(_filter)
    local event = nil
    local p = promise.new()

    event = RegisterNetEvent("Utility:Net:GetServerEntities", function(entities)
        local _entities = nil

        -- Resolve keys from indices
        if _filter.select then
            _entities = {}

            for _, entity in ipairs(entities) do
                local _entity = {}
                for _, key in ipairs(_filter.select) do
                    _entity[key] = entity[_]
                end

                table.insert(_entities, _entity)
            end
        else
            _entities = entities
        end

        p:resolve(_entities)
        RemoveEventHandler(event)
    end)

    TriggerServerEvent("Utility:Net:GetServerEntities", _filter)
    return Citizen.Await(p)
end)

exports("CanEntityBeRendered", function(uNetId, object, slices)
    return CanEntityBeRendered(uNetId, object, slices or GetActiveSlices())
end)

exports("InternalFindFromNetId", UtilityNet.InternalFindFromNetId)