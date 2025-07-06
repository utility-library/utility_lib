local NextId = 1
local Entities = {}

UtilityNet = UtilityNet or {}

-- options = {
--     resource = string (used internally)
--     replace = boolean (replace an already existing object, without creating a new one)
--     searchDistance = number (default 5.0, replace search distance)
--     door = boolean (if true will spawn the entity with door flag)
-- }

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

    TriggerLatentClientEvent("Utility:Net:EntityCreated", -1, 5120, callId, object)
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
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityDeleting", uNetId)

    -- EntityDeleting event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then
        return
    end
    --#endregion


    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    if entity then
        Entities[entity.slice][entity.id] = nil
    end

    TriggerLatentClientEvent("Utility:Net:RequestDeletion", -1, 5120, uNetId)
    ClearEntityStates(uNetId) -- Clear states after trigger
end

UtilityNet.InternalFindFromNetId = function(uNetId)
    for sliceI, slice in pairs(Entities) do
        if slice[uNetId] then
            return slice[uNetId], sliceI
        end
    end
end

UtilityNet.GetEntities = function(slice)
    if slice then
        return Entities[slice]
    else
        return Entities
    end
end

UtilityNet.SetModelRenderDistance = function(model, distance)
    if type(model) == "string" then
        model = GetHashKey(model)
    end

    local _ = GlobalState.ModelsRenderDistance
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

    -- Except caller since it will be already updated
    TriggerLatentClientEvent("Utility:Net:RefreshRotation", -1, 5120, uNetId, newRotation, skipRotationUpdate)
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
    
    -- Except caller since it will be already updated
    TriggerLatentClientEvent("Utility:Net:RefreshCoords", -1, 5120, uNetId, newCoords, skipPositionUpdate)
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
    TriggerLatentClientEvent("Utility:Net:RefreshModel", -1, 5120, uNetId, model)
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

    RegisterNetEvent("Utility:Net:AttachToEntity", function(uNetId, object, params)
        local state = UtilityNet.State(uNetId)
        state.__attached = {
            object = object,
            params = params
        }
    end)

    RegisterNetEvent("Utility:Net:DetachEntity", function(uNetId, newCoords)
        local state = UtilityNet.State(uNetId)

        if state.__attached then
            -- Update entity coords
            if newCoords then
                UtilityNet.SetEntityCoords(uNetId, newCoords)
            end
            
            state.__attached = nil
        end
    end)

    RegisterNetEvent("Utility:Net:SetEntityCoords", UtilityNet.SetEntityCoords)
    RegisterNetEvent("Utility:Net:SetEntityModel", UtilityNet.SetEntityModel)
    RegisterNetEvent("Utility:Net:SetEntityRotation", UtilityNet.SetEntityRotation)

    RegisterNetEvent("Utility:Net:GetEntities", function()
        TriggerClientEvent("Utility:Net:GetEntities", source, UtilityNet.GetEntities())
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