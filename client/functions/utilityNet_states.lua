EntitiesStates = {}

RegisterNetEvent("Utility:Net:UpdateStateValue", function(uNetId, key, value)
    if not EntitiesStates[uNetId] then
        EntitiesStates[uNetId] = {}
    end

    EntitiesStates[uNetId][key] = value
end)

RegisterNetEvent("Utility:Net:SendState", function(uNetId, states)
    EntitiesStates[uNetId] = states    
end)

GetEntityStateValue = function(uNetId, key)
    if not EntitiesStates[uNetId] then
        return
    end

    return EntitiesStates[uNetId][key]
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