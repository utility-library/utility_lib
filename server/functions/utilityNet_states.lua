EntitiesStates = {}

--#region Register and Clear
RegisterEntityState = function(uNetId)
    if not EntitiesStates[uNetId] then
        EntitiesStates[uNetId] = {
            created = GetGameTimer(),
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
        if key then
            return EntitiesStates[uNetId].states[key]
        else
            return EntitiesStates[uNetId].states
        end
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
        TriggerEvent("Utility:Net:UpdateStateValue", uNetId, key, value)
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

CallFunctionForListeners = function(uNetId, fn)
    if GetLifetimeOfState(uNetId) > 5000 then
        for k,v in pairs(EntitiesStates[uNetId].listeners) do
            fn(v)
        end
    else -- If entity is pretty new we call the function for every single person (since it could be still rendering for someone)
        local players = GetPlayers()

        for k,v in pairs(players) do
            fn(v)
        end
    end
end

TriggerEventForListeners = function(event, uNetId, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    local args = {...}
    CallFunctionForListeners(uNetId, function(v) 
        TriggerClientEvent(event, v, table.unpack(args))
    end)
end

TriggerEventForListenersExcept = function(event, uNetId, source, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    local args = {...}
    CallFunctionForListeners(uNetId, function(v)
        if v ~= source then
            TriggerClientEvent(event, v, table.unpack(args))
        end
    end)
end

TriggerLatentEventForListeners = function(event, uNetId, speed, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    local args = {...}
    CallFunctionForListeners(uNetId, function(v)
        TriggerLatentClientEvent(event, v, speed or 5120, table.unpack(args))
    end)
end

TriggerLatentEventForListenersExcept = function(event, uNetId, speed, source, ...)
    if not EntitiesStates[uNetId] then
        return
    end

    local args = {...}
    CallFunctionForListeners(uNetId, function(v)
        if v ~= source then
            TriggerLatentClientEvent(event, v, speed or 5120, table.unpack(args))
        end
    end)
end

GetLifetimeOfState = function(uNetId)
    if not EntitiesStates[uNetId] then
        return 0
    end

    return GetGameTimer() - EntitiesStates[uNetId].created
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
        warn("GetState: No state found for "..uNetId)
        TriggerClientEvent("Utility:Net:GetState"..uNetId, source, nil)
        return
    end

    ListenStateUpdates(source, uNetId)
    TriggerClientEvent("Utility:Net:GetState"..uNetId, source, EntitiesStates[uNetId].states)
end)

local _EMPTY_STATE = {}
RegisterNetEvent("Utility:Net:GetStates", function(uNetIds)
    local source = source
    local states = {}

    for k,v in pairs(uNetIds) do
        if not EntitiesStates[v] then
            warn("GetStates: No states found for "..table.concat(uNetIds, ", "))
            states[v] = _EMPTY_STATE
        else
            ListenStateUpdates(source, v)
            states[v] = EntitiesStates[v].states
        end
    end

    TriggerClientEvent("Utility:Net:GetStates", source, states)
end)

-- Single value
RegisterNetEvent("Utility:Net:GetStateValue", function(uNetId, key)
    local source = source

    if not EntitiesStates[uNetId] then
        warn("GetStateValue: No state found for "..uNetId)
        TriggerClientEvent("Utility:Net:GetStateValue"..uNetId, source, nil)
        return
    end

    TriggerClientEvent("Utility:Net:GetStateValue"..uNetId, source, EntitiesStates[uNetId].states[key])
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