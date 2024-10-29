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

GetEntityIndexByNetId = function(netId)
    for k, v in pairs(GlobalState.Entities) do
        if v.id == netId then
            return k
        end
    end
end

RenderLocalEntity = function(entityIndex, uNetId, coords, model, options)
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

    -- "Disable" the entity
    SetEntityVisible(obj, false)
    SetEntityCollision(obj, false, false)

    if options.rotation then
        SetEntityRotation(obj, options.rotation)
    end
    
    if state.__attached then
        AttachToEntity(obj, state.__attached.object, state.__attached.params)
    end

    LocalEntities[uNetId] = obj

    TriggerServerEvent("Utility:Net:GetState", uNetId) -- Fetch initial states
    TriggerLatentServerEvent("Utility:Net:ListenStateUdpates", 5120, uNetId) -- Listen for future state updates

    local start = GetGameTimer()
    while EntitiesStates[uNetId] == nil do
        if GlobalState.Entities[entityIndex] == nil then
            warn("Entity "..uNetId.." ("..GetEntityArchetypeName(obj)..") was deleted from net before state was fetched, aborting local replication")
            UnrenderLocalEntity(uNetId)
            return
        end

        if GetGameTimer() - start > 500 then
            warn("Failed to fetch state of "..uNetId.." ("..GetEntityArchetypeName(obj)..") after 500ms, aborting local replication")
            UnrenderLocalEntity(uNetId)
            return
        end
        Citizen.Wait(1)
    end

    -- "Enable" the entity, this is done after the state has been fetched to avoid props appearing and then disappearing, state fetch can go wrong if the entity has been deleted
    SetEntityVisible(obj, true)
    SetEntityCollision(obj, true, true)

    TriggerEvent("Utility:Net:OnRender", uNetId, obj, model)

    -- Handle attach, detach
    local state = Entity(obj).state
    state.rendered = true
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

        state.rendered = false
        EntitiesStates[uNetId] = nil
        TriggerLatentServerEvent("Utility:Net:RemoveStateListener", 5120, uNetId)
    end

    LocalEntities[uNetId] = nil
end

UpdateLocalEntity = function(uNetId, entityIndex, slices, entities, modelsRenderDistance)
    local coords = GetEntityCoords(PlayerPedId())

    entities = entities or GlobalState.Entities
    modelsRenderDistance = modelsRenderDistance or GlobalState.ModelsRenderDistance
    entityIndex = entityIndex or GetEntityIndexByNetId(uNetId)

    local entityData = entities[entityIndex]
    
    -- Entity doesn't exist
    if not entityData then
        return
    end

    -- Load slices if not provided
    if not slices then
        slices = {}
        
        -- Add current slice and surrounding slices to the list
        slices[currentSlice] = true
    
        for _, v in pairs(GetSurroundingSlices(currentSlice)) do
            slices[v] = true
        end
    end

    local entity = UtilityNet.GetEntityFromUNetId(uNetId)

    -- Is in a drawing slice
    if not slices[entityData.slice] then
        if entity then
            UnrenderLocalEntity(uNetId)
        end
        return
    end

    local state = UtilityNet.State(uNetId)

    -- Can be rendered
    if ((#(entityData.coords - coords) > (modelsRenderDistance[entityData.model] or 50.0)) and not state.__attached) then
        if entity then
            UnrenderLocalEntity(uNetId)
        end
        return
    end


    if not DoesEntityExist(entity) then
        if entity then
            --print("Before rendering unrender old entity", uNetId)
            UnrenderLocalEntity(uNetId)
        end

        entity = RenderLocalEntity(entityIndex, uNetId, entityData.coords, entityData.model, entityData.options)
    end

    --[[ if state.__attached and not IsEntityAttached(entity) then
        AttachToEntity(entity, state.__attached.object, state.__attached.params)
    elseif not state.__attached and IsEntityAttached(entity) then
        DetachEntity(entity, true, true)
    end ]]
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
    
            local entities = GlobalState.Entities
            local modelsRenderDistance = GlobalState.ModelsRenderDistance

            local coords = GetEntityCoords(player)
            local slices = {}
            
            -- Add current slice and surrounding slices to the list
            slices[currentSlice] = true

            for _, v in pairs(GetSurroundingSlices(currentSlice)) do
                slices[v] = true
            end

            for i, v in pairs(entities) do
                UpdateLocalEntity(v.id, i, slices, entities, modelsRenderDistance)
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

RegisterNetEvent("Utility:Net:EntityCreated", function(_callId, uNetId)
    local event = nil
    local entityIndex = nil

    while not entityIndex do
        entityIndex = GetEntityIndexByNetId(uNetId)
        Citizen.Wait(1)
    end

    UpdateLocalEntity(uNetId, entityIndex)
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