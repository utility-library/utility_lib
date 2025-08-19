EntitiesStates = {}

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
        --print("DONT EXIST REQUEST KEY", uNetId, key)
        return ServerRequestEntityKey(uNetId, key)
    else
        EnsureStateLoaded(uNetId)

        --print("EXISTS", uNetId, EntitiesStates[uNetId], EntitiesStates[uNetId][key])
        return EntitiesStates[uNetId][key]
    end
end

ServerRequestEntityKey = function(uNetId, key)
    local p = promise:new()
    local event = nil

    event = RegisterNetEvent("Utility:Net:GetStateValue"..uNetId, function(value)
        RemoveEventHandler(event)
        p:resolve(value)
    end)
    
    TriggerServerEvent("Utility:Net:GetStateValue", uNetId, key)
    return Citizen.Await(p)
end

ServerRequestEntityStates = function(uNetId)
    EntitiesStates[uNetId] = promise:new() -- Set as loading
    EntitiesStates[uNetId].__promise = true
    
    local p = promise:new()
    local event = nil

    event = RegisterNetEvent("Utility:Net:GetState"..uNetId, function(states)
        RemoveEventHandler(event)
        p:resolve(states)
    end)
    
    TriggerServerEvent("Utility:Net:GetState", uNetId)
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
    local event = nil

    event = RegisterNetEvent("Utility:Net:GetStates", function(states)
        RemoveEventHandler(event)
        p:resolve(states)
    end)
    
    TriggerServerEvent("Utility:Net:GetStates", uNetIds)
    local states = Citizen.Await(p)

    for uNetId, states in pairs(states) do
        EntitiesStates[uNetId]:resolve(true)
        EntitiesStates[uNetId] = states
    end
end

exports("GetEntityStateValue", GetEntityStateValue)



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