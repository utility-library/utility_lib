local NextId = 1
local StateKeys = {}
UtilityNet = {}

UtilityNet.CreateEntity = function(model, coords, options)
    --#region Checks
    if not model or (type(model) ~= "string" and type(model) ~= "number") then
        error("Invalid model, got "..type(model).." expected string", 2)
    else
        if type(model) == "string" then
            model = GetHashKey(model)
        end
    end

    if not coords or type(coords) ~= "vector3" then
        error("Invalid coords, got "..type(coords).." expected vector3", 2)
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
    if not StateKeys[uNetId] then
        StateKeys[uNetId] = {}
    end

    StateKeys[uNetId][key] = true
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
end
--#endregion

-- Exports for server native.lua
exports("CreateEntity", UtilityNet.CreateEntity)
exports("DeleteEntity", UtilityNet.DeleteEntity)
exports("SetModelRenderDistance", UtilityNet.SetModelRenderDistance)
exports("EnsureStateKey", UtilityNet.EnsureStateKey)
