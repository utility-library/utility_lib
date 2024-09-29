local AttachToEntity = function(obj, to, params)
    local attachToObj = nil

    if not params.isUtilityNet then
        attachToObj = NetworkGetEntityFromNetworkId(to)
    else
        local obj = UtilityNet.GetEntityFromUNetId(to)

        if DoesEntityExist(obj) then
            attachToObj = obj
        end
    end

    if attachToObj then
        print("Attaching", obj.." ("..GetEntityArchetypeName(obj)..")", "with", tostring(attachToObj).." ("..GetEntityArchetypeName(attachToObj)..")")
        AttachEntityToEntity(obj, attachToObj, params.bone, params.pos, params.rot, false, params.useSoftPinning, params.collision, true, params.rotationOrder, params.syncRot)
    end
end

RenderLocalEntity = function(uNetId, coords, model, options)
    options = options or {}
    local obj = 0
    local state = UtilityNet.State(uNetId)

    if options.replace then
        local attempts = 0
        
        while attempts < 5 and not DoesEntityExist(obj) do
            obj = GetClosestObjectOfType(coords.xyz, options.searchDistance or 5.0, model)
            attempts = attempts + 1
            Citizen.Wait(500)
        end

        if attempts >= 5 and not DoesEntityExist(obj) then
            warn("Failed to find object to replace, model: "..model.." coords: "..coords.." uNetId:"..uNetId)
            return
        end

        -- If found keep it alive on unrender
        Entity(obj).state.keepAlive = true
    else
        obj = CreateObject(model, coords, false)
        SetEntityCoords(obj, coords) -- This is required to ignore the pivot
    end

    if options.rotation then
        SetEntityRotation(obj, options.rotation)
    end
    
    if state.__attached then
        AttachToEntity(obj, state.__attached.object, state.__attached.params)
    end

    LocalEntities[uNetId] = obj

    TriggerServerEvent("Utility:Net:GetState", uNetId) -- Fetch initial states
    TriggerServerEvent("Utility:Net:ListenStateUdpates", uNetId) -- Listen for future state updates

    while EntitiesStates[uNetId] == nil do
        Citizen.Wait(1)
    end

    TriggerEvent("Utility:Net:OnRender", uNetId, obj, model)

    -- Handle attach, detach
    local state = Entity(obj).state
    state.changeHandler = UtilityNet.AddStateBagChangeHandler(uNetId, function(key, value)
        if key == "__attached" then
            if value then
                --print("Attach")
                AttachToEntity(obj, value.object, value.params)
            else
                --print("Detach")
                DetachEntity(obj, true, true)
            end
        end
    end)

    return obj
end

UnrenderLocalEntity = function(uNetId)
    local entity = UtilityNet.GetEntityFromUNetId(uNetId)

    if DoesEntityExist(LocalEntities[uNetId]) then
        TriggerEvent("Utility:Net:OnUnrender", uNetId, entity, GetEntityModel(entity))
        Citizen.Wait(1)

        if not LocalEntities[uNetId] then
            return
        end

        local state = Entity(LocalEntities[uNetId]).state

        if state.changeHandler then
            UtilityNet.RemoveStateBagChangeHandler(state.changeHandler)
            state.changeHandler = nil
        end

        if not state.keepAlive then
            if state.preserved then
                SetEntityAsNoLongerNeeded(LocalEntities[uNetId])
            else
                DeleteEntity(LocalEntities[uNetId])
            end
        end

        EntitiesStates[uNetId] = nil
        TriggerServerEvent("Utility:Net:RemoveStateListener", uNetId)
    end

    LocalEntities[uNetId] = nil
end

StartUtilityNetRenderLoop = function()
    CreateLoop(function(loopId)
        local entities = GlobalState.Entities
        local modelsRenderDistance = GlobalState.ModelsRenderDistance

        if #entities > 0 then
            local isLoading = false

            while not HasCollisionLoadedAroundEntity(player) or not NetworkIsPlayerActive(PlayerId()) do
                isLoading = true
                Citizen.Wait(100)
            end

            if isLoading then
                Citizen.Wait(1000)
            end
    
            local coords = GetEntityCoords(player)
            local slices = {}
            
            -- Add current slice and surrounding slices to the list
            slices[currentSlice] = true

            for _, v in pairs(GetSurroundingSlices(currentSlice)) do
                slices[v] = true
            end

            for _, v in pairs(entities) do
                local uNetId = v.id
                local entity = UtilityNet.GetEntityFromUNetId(uNetId)
                local state = UtilityNet.State(uNetId)

                -- Is in a drawing slice
                if slices[v.slice] and ((#(v.coords - coords) < (modelsRenderDistance[v.model] or 50.0)) or state.__attached) then
                    if not DoesEntityExist(entity) then
                        if entity and not DoesEntityExist(entity) then
                            --print("Before rendering unrender old entity", uNetId)
                            UnrenderLocalEntity(uNetId)
                        end
    
                        entity = RenderLocalEntity(uNetId, v.coords, v.model, v.options)
                    end

                    --[[ if state.__attached and not IsEntityAttached(entity) then
                        AttachToEntity(entity, state.__attached.object, state.__attached.params)
                    elseif not state.__attached and IsEntityAttached(entity) then
                        DetachEntity(entity, true, true)
                    end ]]
                else
                    if entity then
                        UnrenderLocalEntity(uNetId)
                    end
                end
            end
        end
    end, Config.UpdateCooldown)
end

RegisterNetEvent("Utility:Net:RefreshCoords", function(uNetId, coords)
    if LocalEntities[uNetId] then
        SetEntityCoords(LocalEntities[uNetId], coords)
    end
end)

RegisterNetEvent("Utility:Net:RefreshRotation", function(uNetId, rotation)
    if LocalEntities[uNetId] then
        SetEntityRotation(LocalEntities[uNetId], rotation)
    end
end)

-- Unrender entities on resource stop
AddEventHandler("onResourceStop", function(resource)
    local entities = GlobalState.Entities
    for k, v in pairs(entities) do
        if v.createdBy == resource then
            UnrenderLocalEntity(v.id)
        end
    end
end)

-- Exports
UtilityNet.GetEntityFromUNetId = function(uNetId)
    return LocalEntities[uNetId]
end

UtilityNet.GetUNetIdFromEntity = function(entity)
    for k, v in pairs(LocalEntities) do
        if v == entity then
            return k
        end
    end
end

exports("GetEntityFromUNetId", UtilityNet.GetEntityFromUNetId)
exports("GetUNetIdFromEntity", UtilityNet.GetUNetIdFromEntity)
exports("GetRenderedEntities", function() return LocalEntities end)