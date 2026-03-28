EntitiesStates = {}

local PendingStateValueRequests = {}
local PendingStateRequests = {}
local PendingStatesRequests = {}

local __requestId = 0
local function NextRequestId()
    __requestId = __requestId + 1

    if __requestId >= 2147483647 then
        __requestId = 1
    end

    return tostring(__requestId)
end

function DoesEntityStateExist(uNetId)
    return EntitiesStates[uNetId] ~= nil
end

function IsEntityStateLoading(uNetId)
    if not EntitiesStates[uNetId] then
        return false
    end

    return EntitiesStates[uNetId].__promise
end

function EnsureStateLoaded(uNetId)
    if not DoesEntityStateExist(uNetId) then
        return
    end

    if IsEntityStateLoading(uNetId) then
        Citizen.Await(EntitiesStates[uNetId])
    end
end

RegisterNetEvent("Utility:Net:UpdateStateValue", function(uNetId, key, value)
    EnsureStateLoaded(uNetId)

    if not EntitiesStates[uNetId] then
        EntitiesStates[uNetId] = {}
    end

    EntitiesStates[uNetId][key] = value
end)

GetEntityStateValue = function(uNetId, key)
     -- If state is not loaded it means that the entity doesnt exist locally
    if not DoesEntityStateExist(uNetId) then
        return ServerRequestEntityKey(uNetId, key)
    else
        EnsureStateLoaded(uNetId)

        return EntitiesStates[uNetId][key]
    end
end

ServerRequestEntityKey = function(uNetId, key)
    local p = promise:new()
    local requestId = NextRequestId()
    PendingStateValueRequests[requestId] = p
    
    TriggerServerEvent("Utility:Net:GetStateValue", requestId, uNetId, key)

    return Citizen.Await(p)
end

ServerRequestEntityStates = function(uNetId)
    EntitiesStates[uNetId] = promise:new() -- Set as loading
    EntitiesStates[uNetId].__promise = true

    local p = promise:new()
    local requestId = NextRequestId()
    PendingStateRequests[requestId] = p

    TriggerServerEvent("Utility:Net:GetState", requestId, uNetId)

    local states = Citizen.Await(p)

    EntitiesStates[uNetId]:resolve(true)
    EntitiesStates[uNetId] = states or {}
end

ServerRequestEntitiesStates = function(uNetIds)
    for i=1, #uNetIds do
        EntitiesStates[uNetIds[i]] = promise:new() -- Set as loading
        EntitiesStates[uNetIds[i]].__promise = true
    end

    local p = promise:new()
    local requestId = NextRequestId()
    PendingStatesRequests[requestId] = p

    TriggerServerEvent("Utility:Net:GetStates", requestId, uNetIds)
    local states = Citizen.Await(p) or {}

    for i = 1, #uNetIds do
        local uNetId = uNetIds[i]

        EntitiesStates[uNetId]:resolve(true)
        EntitiesStates[uNetId] = states[uNetId] or {}
    end
end

exports("GetEntityStateValue", GetEntityStateValue)


----

RegisterNetEvent("Utility:Net:GetStateValue:Response", function(requestId, value)
    local p = PendingStateValueRequests[requestId]
    if not p then
        return
    end

    PendingStateValueRequests[requestId] = nil
    p:resolve(value)
end)

RegisterNetEvent("Utility:Net:GetState:Response", function(requestId, states)
    local p = PendingStateRequests[requestId]
    if not p then
        return
    end

    PendingStateRequests[requestId] = nil
    p:resolve(states)
end)

RegisterNetEvent("Utility:Net:GetStates:Response", function(requestId, states)
    local p = PendingStatesRequests[requestId]
    if not p then
        return
    end

    PendingStatesRequests[requestId] = nil
    p:resolve(states)
end)




--[[ RegisterNetEvent("Utility:Net:OnRender", function(uNetid, obj, model)
    print("Attaching change handler to", uNetid)

    Citizen.CreateThread(function()
        while true do
            local state = UtilityNet.State(uNetid)

            if state.random then
                DrawText3Ds(GetEntityCoords(obj), "key: "..state.random.key.." key2: "..state.random.key2)

                if state.random.deep then
                    DrawText3Ds(GetEntityCoords(obj) + vec3(0.0, 0.0, 0.5), "deep: "..state.random.deep.deep2)
                end
            end
        
            Citizen.Wait(1)
        end
    end)

    UtilityNet.AddStateBagChangeHandler(uNetid, function(key, value)
        print("Updated", key, value)
    end)
end) ]]