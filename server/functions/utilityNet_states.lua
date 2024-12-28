EntitiesStates = {}

--#region Register and Clear
RegisterEntityState = function(uNetId)
    if not EntitiesStates[uNetId] then
        EntitiesStates[uNetId] = {
            listeners = {},
            states = {}
        }
    end
end

ClearEntityStates = function(uNetId)
    if EntitiesStates[uNetId] then
        EntitiesStates[uNetId] = nil
    end
end
--#endregion

-- #region Get, Set, Update
GetEntityStateValue = function(uNetId, key)
    if EntitiesStates[uNetId] then
        return EntitiesStates[uNetId].states[key]
    end
end

SetEntityStateValue = function(uNetId, key, value)
    if not EntitiesStates[uNetId] then
        return
    end
    
    EntitiesStates[uNetId].states[key] = value
    UpdateStateValueForListeners(uNetId, key, value)
end

UpdateStateValueForListeners = function(uNetId, key, value)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        TriggerClientEvent("Utility:Net:UpdateStateValue", v, uNetId, key, value)
    end
end
--#endregion

--#region Listeners
ListenStateUpdates = function(source, uNetId)
    if not EntitiesStates[uNetId] then
        return
    end

    table.insert(EntitiesStates[uNetId].listeners, source)
end

RemoveStateListener = function(source, uNetId)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        if v == source then
            table.remove(EntitiesStates[uNetId].listeners, k)
            break
        end
    end    
end

RemoveStateListenerFromAll = function(source)
    for k,v in pairs(EntitiesStates) do
        RemoveStateListener(source, k)
    end
end

TriggerEventForListeners = function(event, uNetId, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        TriggerClientEvent(event, v, ...)
    end
end

TriggerEventForListenersExcept = function(event, uNetId, source, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        if v ~= source then
            TriggerClientEvent(event, v, ...)
        end
    end
end

TriggerLatentEventForListeners = function(event, uNetId, speed, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        TriggerLatentClientEvent(event, v, speed or 5120, ...)
    end
end

TriggerLatentEventForListenersExcept = function(event, uNetId, speed, source, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    for k,v in pairs(EntitiesStates[uNetId].listeners) do
        if v ~= source then
            TriggerLatentClientEvent(event, v, speed or 5120, ...)
        end
    end
end
--#endregion

--#region Net Events
RegisterNetEvent("Utility:Net:ListenStateUpdates", function(uNetId)
    ListenStateUpdates(source, uNetId)
end)

RegisterNetEvent("Utility:Net:RemoveStateListener", function(uNetId)
    RemoveStateListener(source, uNetId)
end)

RegisterNetEvent("Utility:Net:GetState", function(uNetId)
    local source = source

    if not EntitiesStates[uNetId] then
        TriggerClientEvent("Utility:Net:GetState"..uNetId, source, nil)
        return
    end

    ListenStateUpdates(source, uNetId)
    TriggerClientEvent("Utility:Net:GetState"..uNetId, source, EntitiesStates[uNetId].states)
end)
--#endregion

-- On player disconnect remove all listeners of that player (prevent useless bandwidth usage)
AddEventHandler("playerDropped", function(reason)
    RemoveStateListenerFromAll(source)
end)

exports("GetEntityStateValue", GetEntityStateValue)
exports("SetEntityStateValue", SetEntityStateValue)

--[[ Citizen.CreateThread(function()
    local obj = UtilityNet.CreateEntity("prop_weed_01", vec3(-1268.5847, -3013.3059, -48.4830))
    local state = UtilityNet.State(obj)
    state.random = {}

    while true do
        local rand = math.random(1, 100)
        state.random.key = rand
        state.random.key2 = rand + math.random(1, 100)

        state.random.deep = {}
        state.random.deep.deep2 = math.random(1, 100)

        print(state.random.key, state.random.key2, state.random.deep, state.random.deep.deep2)
        Citizen.Wait(5000)
    end
end) ]]