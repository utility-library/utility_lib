local NextId = 1
local StateKeys = {}

UtilityNet = UtilityNet or {}

-- options = {
--     resource = string (used internally)
--     replace = boolean (replace an already existing object, without creating a new one)
--     searchDistance = number (default 5.0, replace search distance)
-- }

UtilityNet.CreateEntity = function(model, coords, options)
    --#region Checks
    if not model or (type(model) ~= "string" and type(model) ~= "number") then
        error("Invalid model, got "..type(model).." expected string", 0)
    else
        if type(model) == "string" then
            model = GetHashKey(model)
        end
    end

    if not coords or type(coords) ~= "vector3" then
        error("Invalid coords, got "..type(coords).." expected vector3", 0)
    end

    options = options or {}
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityCreating", model, coords, options)

    -- EntityCreating event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then 
        return -1
    end
    --#endregion

    local entities = GlobalState.Entities
    local object = {
        id = NextId,
        model = model,
        coords = coords,
        slice = GetSliceFromCoords(coords),
        options = options,
        createdBy = options.resource or GetInvokingResource(),
    }

    table.insert(entities, object)
    GlobalState.Entities = entities

    NextId = NextId + 1

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

    local entities = GlobalState.Entities

    for k,v in pairs(entities) do
        if v.id == uNetId then
            table.remove(entities, k)
            break
        end
    end

    GlobalState.Entities = entities

    -- Clear all states
    if StateKeys[uNetId] then
        for k,v in pairs(StateKeys[uNetId]) do
            local stateId = "EntityState_"..uNetId.."_"..k
            GlobalState[stateId] = nil
            --print("Cleared", stateId)
        end

        StateKeys[uNetId] = nil
    end

    TriggerClientEvent("Utility:Net:RequestDeletion", -1, uNetId)
end

UtilityNet.SetModelRenderDistance = function(model, distance)
    if type(model) == "string" then
        model = GetHashKey(model)
    end

    local _ = GlobalState.ModelsRenderDistance
    _[model] = distance
    GlobalState.ModelsRenderDistance = _
end

-- We need to store keys setted by every entity for clearing (as of now, there's no way to get the full table under the statebag)
UtilityNet.EnsureStateKey = function(uNetId, key)
    local resource = GetInvokingResource()

    if not StateKeys[uNetId] then
        StateKeys[uNetId] = {}
    end

    StateKeys[uNetId][key] = true
end

UtilityNet.SetEntityRotation = function(uNetId, newRotation)
    local entities = GlobalState.Entities

    if type(newRotation) ~= "vector3" then
        error("Invalid rotation, got "..type(newRotation).." expected vector3", 2)
    end

    for k,v in pairs(entities) do
        if v.id == uNetId then
            v.options.rotation = newRotation
            break
        end
    end

    GlobalState.Entities = entities

    -- This is to refresh the rotation also for currently rendering objects
    TriggerClientEvent("Utility:Net:RefreshRotation", -1, uNetId, newRotation)
end

UtilityNet.SetEntityCoords = function(uNetId, newCoords)
    local entities = GlobalState.Entities

    if type(newCoords) ~= "vector3" then
        error("Invalid coords, got "..type(newCoords).." expected vector3", 2)
    end

    for k,v in pairs(entities) do
        if v.id == uNetId then
            v.coords = newCoords
            v.slice = GetSliceFromCoords(newCoords)
            break
        end
    end

    GlobalState.Entities = entities
    -- This is to refresh the coords also for currently rendering objects
    TriggerClientEvent("Utility:Net:RefreshCoords", -1 , uNetId, newCoords)
end

--#region Events
UtilityNet.RegisterEvents = function()
    RegisterNetEvent("Utility:Net:CreateEntity", function(callId, model, coords, options)
        local entity = UtilityNet.CreateEntity(model, coords, options)
    
        -- Call callback event
        TriggerClientEvent("Utility:Net:EntityCreated"..callId, -1, entity)
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
            UtilityNet.SetEntityCoords(uNetId, newCoords)
            state.__attached = nil
        end
    end)

    RegisterNetEvent("Utility:Net:SetEntityCoords", UtilityNet.SetEntityCoords)
    RegisterNetEvent("Utility:Net:SetEntityRotation", UtilityNet.SetEntityRotation)

    -- Clear all entities on resource stop (this will prevent also statebag leaks)
    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            for k,v in pairs(GlobalState.Entities) do
                --print("Stopped utility deleting", v.id)
                UtilityNet.DeleteEntity(v.id)
            end
        end
    end)
end
--#endregion

-- Exports for server native.lua
exports("CreateEntity", UtilityNet.CreateEntity)
exports("DeleteEntity", UtilityNet.DeleteEntity)
exports("SetModelRenderDistance", UtilityNet.SetModelRenderDistance)
exports("EnsureStateKey", UtilityNet.EnsureStateKey)

exports("SetEntityCoords", UtilityNet.SetEntityCoords)
exports("SetEntityRotation", UtilityNet.SetEntityRotation)