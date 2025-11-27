local NextId = 1
local Entities = {}
local AttachedEntities = {}

UtilityNet = UtilityNet or {}

-- options = {
--     resource = string (used internally)
--     replace = boolean (replace an already existing object, without creating a new one)
--     searchDistance = number (default 5.0, replace search distance)
--     door = boolean (if true will spawn the entity with door flag)
-- }

TriggerClientEventNearSlice = function(name, slice, ...)
    local players = GetPlayers()

    for k,v in pairs(players) do
        local currentSlice = GetSliceFromCoords(GetEntityCoords(GetPlayerPed(v)))

        if slice == currentSlice then
            TriggerLatentClientEvent(name, v, -1, ...)
        end

        local slices = GetSurroundingSlices(currentSlice)

        for i=1, #slices do
            if slice == slices[i] then
                TriggerLatentClientEvent(name, v, -1, ...)
            end
        end
    end
end

UtilityNet.CreateEntity = function(model, coords, options, callId)
    options = options or {}
    local hashmodel = nil

    --#region Checks
    if not model or (type(model) ~= "string" and type(model) ~= "number") then
        error("Invalid model, got "..type(model).." expected string or number", 0)
    else
        if type(model) == "string" then
            hashmodel = GetHashKey(model)
        else
            hashmodel = model
        end
    end

    if not coords or type(coords) ~= "vector3" then
        error("Invalid coords, got "..type(coords).." expected vector3", 0)
    end
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityCreating", hashmodel, coords, options)

    -- EntityCreating event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then 
        return -1
    end
    --#endregion

    local slice = GetSliceFromCoords(coords)
    
    -- If you edit this, make sure to update also the encoder/decoder!
    local object = {
        id = NextId,
        model = options.abstract and model or hashmodel,
        coords = coords,
        slice = slice,
        options = options,
        createdBy = options.createdBy or GetInvokingResource(),
    }

    if not Entities[slice] then
        Entities[slice] = {}
    end

    Entities[slice][object.id] = object

    RegisterEntityState(object.id)
    NextId = NextId + 1

    TriggerLatentClientEvent("Utility:Net:EntityCreated", -1, -1, callId, object)
    return object.id
end

UtilityNet.DeleteEntity = function(uNetId)
    --#region Checks
    if type(uNetId) ~= "number" then
        error("Invalid uNetId, got "..type(uNetId).." expected number", 2)
        return
    end

    -- Invalid Id
    if uNetId == -1 then
        error("Invalid uNetId, got -1", 2)
        return
    end

    -- Exist?
    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    if not entity then
        return
    end
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityDeleting", uNetId)

    -- EntityDeleting event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then
        return
    end
    --#endregion

    Entities[entity.slice][entity.id] = nil
    AttachedEntities[uNetId] = nil

    TriggerLatentClientEvent("Utility:Net:RequestDeletion", -1, -1, uNetId, entity.model, entity.coords, entity.options.rotation)
    ClearEntityStates(uNetId) -- Clear states after trigger
    
    TriggerEvent("Utility:Net:EntityDeleted", uNetId)
end

UtilityNet.InternalFindFromNetId = function(uNetId)
    for sliceI, slice in pairs(Entities) do
        if slice[uNetId] then
            return slice[uNetId], sliceI
        end
    end
end

UtilityNet.GetEntities = function(slice)
    local entities = {}

    if slice then
        if type(slice) == "table" then
            for i, slice in pairs(slice) do
                entities[slice] = Entities[slice]
            end
    
            return entities
        else
            return Entities[slice]
        end
    else
        return Entities
    end
end

UtilityNet.SetModelRenderDistance = function(model, distance)
    if type(model) == "string" then
        model = GetHashKey(model)
    end

    local _ = GlobalState.ModelsRenderDistance or {}
    _[model] = distance
    GlobalState.ModelsRenderDistance = _
end

UtilityNet.SetEntityRotation = function(uNetId, newRotation, skipRotationUpdate)
    local source = source

    if type(newRotation) ~= "vector3" then
        error("Invalid rotation, got "..type(newRotation).." expected vector3", 2)
    end

    if newRotation.x ~= newRotation.x or newRotation.y ~= newRotation.y or newRotation.z ~= newRotation.z then
        error("Invalid rotation, got "..type(newRotation).." (with NaN) expected vector3", 2)
    end


    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    Entities[slice][uNetId].options.rotation = newRotation

    TriggerClientEventNearSlice("Utility:Net:RefreshRotation", slice, uNetId, newRotation, skipRotationUpdate)
end

UtilityNet.SetEntityCoords = function(uNetId, newCoords, skipPositionUpdate)
    local source = source

    if type(newCoords) ~= "vector3" then
        error("Invalid coords, got "..type(newCoords).." expected vector3", 2)
    end

    if newCoords.x ~= newCoords.x or newCoords.y ~= newCoords.y or newCoords.z ~= newCoords.z then
        error("Invalid coords, got "..type(newCoords).." (with NaN) expected vector3", 2)
    end

    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)
    local newSlice = GetSliceFromCoords(newCoords)

    if newSlice ~= slice then
        local old = Entities[slice][uNetId]

        if not Entities[newSlice] then
            Entities[newSlice] = {}
        end

        Entities[slice][uNetId] = nil
        Entities[newSlice][uNetId] = old

        slice = newSlice
    end
    Entities[slice][uNetId].coords = newCoords
    Entities[slice][uNetId].slice = GetSliceFromCoords(newCoords)
    
    TriggerClientEventNearSlice("Utility:Net:RefreshCoords", slice, uNetId, newCoords, skipPositionUpdate)
end

UtilityNet.SetEntityModel = function(uNetId, model)
    local source = source

    if type(model) ~= "number" and type(model) ~= "string" then
        error("Invalid model, got "..type(model).." expected string or number", 2)
    end

    if type(model) == "string" then
        model = GetHashKey(model)
    end

    local entity, slice = UtilityNet.InternalFindFromNetId(uNetId)

    Entities[slice][uNetId].model = model

    -- Except caller since it will be already updated
    local players = GetPlayers()

    TriggerClientEventNearSlice("Utility:Net:RefreshModel", slice, uNetId, model)
end

local GetAttachedEntitySliceAndCoords = function(uNetId, __attached)
    __attached = __attached or UtilityNet.State(uNetId).__attached

    if __attached.params.isUtilityNet then
        -- Get uNetId entity info
        if not UtilityNet.DoesUNetIdExist(__attached.object) then
            warn(uNetId.." is attached to uNetId "..__attached.object.." but it does not exist, detaching")
            UtilityNet.DetachEntity(uNetId, true)
            return nil
        end

        local entity, slice = UtilityNet.InternalFindFromNetId(__attached.object)

        return slice, entity.coords
    else
        -- Get network entity info
        local success, entity = pcall(NetworkGetEntityFromNetworkId, __attached.object)

        if not success or entity == 0 then
            warn(uNetId.." is attached to netId "..__attached.object.." but it does not exist, detaching")
            UtilityNet.DetachEntity(uNetId, true)
            return nil
        end

        local slice = GetSliceFromCoords(GetEntityCoords(entity))
        local coords = GetEntityCoords(entity)

        return slice, coords
    end
end

local sliceUpdateRunning = false
local StartSliceUpdateForAttachedEntities = function()
    if sliceUpdateRunning then
        return
    end
    Citizen.CreateThread(function()
        sliceUpdateRunning = true

        while not table.empty(AttachedEntities) do
            for uNetId, __attached in pairs(AttachedEntities) do
                local selfEntity, selfSlice = UtilityNet.InternalFindFromNetId(uNetId)
                -- Entity not found
                if not selfEntity or not selfSlice then
                    warn("SliceUpdateForAttachedEntities: Entity "..tostring(uNetId).." not found, removing from attached entities")
                    AttachedEntities[uNetId] = nil
                    goto continue
                end

                local attachedSlice, attachedCoords = GetAttachedEntitySliceAndCoords(uNetId, __attached)
                
                if not attachedSlice or not attachedCoords then
                    goto continue
                end

                -- Need to call SetEntityCoords since it will update the slice also for loaded clients
                -- otherwise it will be updated only on the server, and not on the clients
                if attachedSlice ~= selfSlice or #(attachedCoords - selfEntity.coords) > 10.0 then
                    --print("Updating entity "..uNetId.." slice from "..selfSlice.." to "..attachedSlice)
                    UtilityNet.SetEntityCoords(uNetId, attachedCoords, true)
                end

                ::continue::
            end
            Citizen.Wait(5000)
        end

        sliceUpdateRunning = false
    end)
end

UtilityNet.AttachTo = function(uNetId, to, params)
    local state = UtilityNet.State(uNetId)
    local __attached = {
        object = to,
        params = params
    }

    state.__attached = __attached
    AttachedEntities[uNetId] = __attached
    StartSliceUpdateForAttachedEntities()
end

UtilityNet.DetachEntity = function(uNetId, skipPositionUpdate)
    local state = UtilityNet.State(uNetId)

    if state.__attached then
        if not skipPositionUpdate then
            local _slice, coords = GetAttachedEntitySliceAndCoords(uNetId, state.__attached)
            
            if coords then
                UtilityNet.SetEntityCoords(uNetId, coords) -- Update last coords on detach
            end
        end

        state.__attached = nil
        AttachedEntities[uNetId] = nil
    end
end

local EncodeEntitiesForClient = function(entities)
    if table.empty(entities) then
        return {}
    end

    local createdBy = {}
    local encoded = {
        groups = { -- groups
            createdBy = createdBy
        },
        entities = {} -- entities
    }

    for slice, entities in pairs(entities) do
        encoded.entities[slice] = {}

        for uNetId, entity in pairs(entities) do
            -- Group entities createdBy based on indexes
            local v, index = table.find(createdBy, entity.createdBy)
            local createdByIndex = nil

            if index then
                createdByIndex = index
            else
                table.insert(createdBy, entity.createdBy)
                createdByIndex = #createdBy
            end

            table.insert(encoded.entities[slice], {
                entity.id or -1,
                entity.model or -1,
                createdByIndex or -1,
                {entity.coords.x, entity.coords.y, entity.coords.z},
                entity.options or {}
            })
        end
    end

    return encoded
end

--#region Events
UtilityNet.RegisterEvents = function()
    RegisterNetEvent("Utility:Net:CreateEntity", function(callId, model, coords, options)
        UtilityNet.CreateEntity(model, coords, options, callId)
    end)
    
    RegisterNetEvent("Utility:Net:DeleteEntity", function(uNetId)
        UtilityNet.DeleteEntity(uNetId)
    end)

    RegisterNetEvent("Utility:Net:SetModelRenderDistance", function(model, distance)
        UtilityNet.SetModelRenderDistance(model, distance)
    end)

    RegisterNetEvent("Utility:Net:AttachTo", function(uNetId, object, params)
        UtilityNet.AttachTo(uNetId, object, params)
    end)

    RegisterNetEvent("Utility:Net:DetachEntity", function(uNetId)
        source = nil -- Force update also for the caller
        UtilityNet.DetachEntity(uNetId)
    end)

    RegisterNetEvent("Utility:Net:SetEntityCoords", UtilityNet.SetEntityCoords)
    RegisterNetEvent("Utility:Net:SetEntityModel", UtilityNet.SetEntityModel)
    RegisterNetEvent("Utility:Net:SetEntityRotation", UtilityNet.SetEntityRotation)

    RegisterNetEvent("Utility:Net:GetEntities", function(slices)
        local source = source
        TriggerLatentClientEvent("Utility:Net:GetEntities", source, -1, EncodeEntitiesForClient(UtilityNet.GetEntities(slices)))
    end)

    RegisterNetEvent("Utility:Net:GetServerEntities", function(_filter)
        local entities = {}

        UtilityNet.ForEachEntity(function(entity)
            if _filter.where then
                for k,v in pairs(_filter.where) do
                    if entity[k] ~= v then
                        return
                    end
                end
            end

            if _filter.select then
                local _entity = {}
                
                for _, key in ipairs(_filter.select) do
                    _entity[_] = entity[key]
                end

                table.insert(entities, _entity)
            else
                table.insert(entities, entity)
            end
        end)
        
        TriggerLatentClientEvent("Utility:Net:GetServerEntities", source, -1, entities)
    end)
end
--#endregion

-- Exports for server native.lua
exports("CreateEntity", UtilityNet.CreateEntity)
exports("DeleteEntity", UtilityNet.DeleteEntity)
exports("SetModelRenderDistance", UtilityNet.SetModelRenderDistance)
exports("GetEntities", UtilityNet.GetEntities)
exports("InternalFindFromNetId", UtilityNet.InternalFindFromNetId)

exports("SetEntityModel", UtilityNet.SetEntityModel)
exports("SetEntityCoords", UtilityNet.SetEntityCoords)
exports("SetEntityRotation", UtilityNet.SetEntityRotation)

exports("AttachTo", UtilityNet.AttachTo)
exports("DetachEntity", UtilityNet.DetachEntity)