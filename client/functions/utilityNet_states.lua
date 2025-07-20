EntitiesStates = {}

local function IsEntityStateLoaded(uNetId)
    return EntitiesStates[uNetId] ~= -1
end

local function EnsureStateLoaded(uNetId)
    if not IsEntityStateLoaded(uNetId) then
        local start = GetGameTimer()
        while not IsEntityStateLoaded(uNetId) do
            if GetGameTimer() - start > 5000 then
                error("WaitUntilStateLoaded: entity "..tostring(uNetId).." state loading timed out")
                break
            end
            Citizen.Wait(1)
        end
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
    EnsureStateLoaded(uNetId)

    if not EntitiesStates[uNetId] then
        warn("GetEntityStateValue: entity "..tostring(uNetId).." has no loaded states, attempted to retrieve key: "..tostring(key))
        return
    end

    return EntitiesStates[uNetId][key]
end

ServerRequestEntityStates = function(uNetId)
    EntitiesStates[uNetId] = -1 -- Set as loading
    
    local p = promise:new()
    local event = nil

    event = RegisterNetEvent("Utility:Net:GetState"..uNetId, function(states)
        RemoveEventHandler(event)
        p:resolve(states)
    end)
    
    TriggerServerEvent("Utility:Net:GetState", uNetId)
    local states = Citizen.Await(p)

    EntitiesStates[uNetId] = states or {}
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