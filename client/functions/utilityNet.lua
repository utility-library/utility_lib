local DebugRendering = false

--#region Local functions
local GetActiveSlices = function()
    local slices = {}
        
    -- Add current slice and surrounding slices to the list
    slices[currentSlice] = true

    for _, v in pairs(GetSurroundingSlices(currentSlice)) do
        slices[v] = true
    end

    return slices
end

local GetEntityIndexByNetId = function(netId)
    for k, v in pairs(GlobalState.Entities) do
        if v.id == netId then
            return k
        end
    end
end

local AttachToEntity = function(obj, to, params)
    local attachToObj = nil

    if not params.isUtilityNet then
        attachToObj = NetworkGetEntityFromNetworkId(to)
    else
        -- Ensure that the entity is fully ready
        if UtilityNet.DoesUNetIdExist(to) then
            while not UtilityNet.IsReady(to) do
                Citizen.Wait(1)
            end
        else
            warn("AttachToEntity: trying to attach "..obj.." to "..to.." but the destination netId doesnt exist")
        end

        attachToObj = UtilityNet.GetEntityFromUNetId(to)
    end

    if attachToObj then
        print("Attaching", obj.." ("..GetEntityArchetypeName(obj)..")", "with", tostring(attachToObj).." ("..GetEntityArchetypeName(attachToObj)..")")
        AttachEntityToEntity(obj, attachToObj, params.bone, params.pos, params.rot, false, params.useSoftPinning, params.collision, true, params.rotationOrder, params.syncRot)
    end
end

local FindEntity = function(coords, radius, model, maxAttempts)
    local attempts = 0
    local obj = 0
        
    while attempts < maxAttempts and not DoesEntityExist(obj) do
        obj = GetClosestObjectOfType(coords.xyz, radius or 5.0, model)
        attempts = attempts + 1
        Citizen.Wait(500)
    end

    if attempts >= maxAttempts and not DoesEntityExist(obj) then
        warn("Failed to find object to replace, model: "..model.." coords: "..coords.." uNetId:"..uNetId)
        return
    end

    return obj
end
--#endregion

--#region Rendering functions
local creatingEntities = {}
local SetNetIdBeignCreated = function(uNetId, status)
    creatingEntities[uNetId] = status and true or nil
end

local IsNetIdCreating = function(uNetId)
    return creatingEntities[uNetId]
end

exports("IsNetIdCreating", IsNetIdCreating)

local UnrenderLocalEntity = function(uNetId)
    local entity = UtilityNet.GetEntityFromUNetId(uNetId)

    if DoesEntityExist(LocalEntities[uNetId]) then
        TriggerEvent("Utility:Net:OnUnrender", uNetId, entity, GetEntityModel(entity))
        Citizen.Wait(1) -- Allow time for any other script to mark the entity as "preserved"

        if not LocalEntities[uNetId] then
            warn("UnrenderLocalEntity: entity with uNetId: "..uNetId.." already unrendered, skipping this call")
            return
        end

        local state = Entity(LocalEntities[uNetId]).state

        -- Remove state change handler (currently used only for attaching)
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

local RenderLocalEntity = function(uNetId)
    if IsNetIdCreating(uNetId) then
        warn("RenderLocalEntity: entity with uNetId: "..uNetId.." is already being created, skipping this call")
        return
    end

    SetNetIdBeignCreated(uNetId, true)

    local obj = 0
    local stateUtility = UtilityNet.State(uNetId)
    local entityIndex = GetEntityIndexByNetId(uNetId)
    local entityData = GlobalState.Entities[entityIndex]

    if not entityData then
        error("RenderLocalEntity: entity with index "..entityIndex.." not found, uNetId: "..uNetId)
        return
    end

    -- Set local variable (for readability)
    local coords = entityData.coords
    local model = entityData.model
    local options = entityData.options

    if options.replace then
        obj = FindEntity(coords, options.searchDistance, model, 5)

        -- If found keep it alive on unrender
        Entity(obj).state.keepAlive = true
    else
        obj = CreateObject(model, coords, false)
        SetEntityCoords(obj, coords) -- This is required to ignore the pivot
    end
    
    local state = Entity(obj).state

    -- "Disable" the entity
    SetEntityVisible(obj, false)
    SetEntityCollision(obj, false, false)
    
    if options.rotation then
        SetEntityRotation(obj, options.rotation)
    end
    
    if stateUtility.__attached then
        AttachToEntity(obj, stateUtility.__attached.object, stateUtility.__attached.params)
    else
        state.changeHandler = UtilityNet.AddStateBagChangeHandler(uNetId, function(key, value)
            -- Exit if entity is no longer valid
            if not DoesEntityExist(obj) then
                UtilityNet.RemoveStateBagChangeHandler(state.changeHandler)
                return
            end

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
    end

    LocalEntities[uNetId] = obj

    -- Fetch initial state
    ServerRequestEntityStates(uNetId)

    -- "Enable" the entity, this is done after the state has been fetched to avoid props doing strange stuffs
    SetEntityVisible(obj, true)
    SetEntityCollision(obj, true, true)

    TriggerEvent("Utility:Net:OnRender", uNetId, obj, model)

    state.rendered = true
    SetNetIdBeignCreated(uNetId, false)

    return obj
end

local CanEntityBeRendered = function(uNetId)
    -- Default values
    local entities = GlobalState.Entities
    local entityIndex = GetEntityIndexByNetId(uNetId)

    local entityData = entities[entityIndex]

    -- Exit if entity data is missing
    if not entityData then
        error("UpdateLocalEntity: entity with index "..tostring(entityIndex).." not found, uNetId: "..tostring(uNetId))
        return false
    end

    local slices = GetActiveSlices()
    local entity = UtilityNet.GetEntityFromUNetId(uNetId)

    -- Check if entity is within drawing slices
    if not slices[entityData.slice] then
        return false
    end

    local state = UtilityNet.State(uNetId)

    -- Render only if within render distance
    if not state.__attached then
        local coords = GetEntityCoords(PlayerPedId())
        local modelsRenderDistance = GlobalState.ModelsRenderDistance
        local renderDistance = modelsRenderDistance[entityData.model] or 50.0

        if #(entityData.coords - coords) > renderDistance then
            return false
        end
    end

    return true
end
--#endregion

StartUtilityNetRenderLoop = function()
    -- Wait for player full load
    local isLoading = false

    while not HasCollisionLoadedAroundEntity(player) or not NetworkIsPlayerActive(PlayerId()) do
        isLoading = true
        Citizen.Wait(100)
    end

    if isLoading then
        Citizen.Wait(1000)
    end

    Citizen.CreateThread(function()
        while true do
            local entities = GlobalState.Entities
            local modelsRenderDistance = GlobalState.ModelsRenderDistance
    
            if #entities > 0 then
                local coords = GetEntityCoords(player)
                local slices = GetActiveSlices()
    
                for i, v in pairs(entities) do
                    local obj = UtilityNet.GetEntityFromUNetId(v.id) or 0
                    local state = Entity(obj).state or {}
    
                    if CanEntityBeRendered(v.id) then
                        if not state.rendered then
                            if DebugRendering then
                                print("RenderLocalEntity", v.id, "Loop")
                            end

                            RenderLocalEntity(v.id)
                        end
                    else
                        if state.rendered then
                            UnrenderLocalEntity(v.id)
                        end
                    end
                end
            end
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
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
    while not UtilityNet.DoesUNetIdExist(uNetId) do
        Citizen.Wait(1)
    end

    if CanEntityBeRendered(uNetId) then
        if DebugRendering then
            print("RenderLocalEntity", uNetId, "EntityCreated")
        end

        RenderLocalEntity(uNetId)
    end
end)

RegisterNetEvent("Utility:Net:RequestDeletion", function(uNetId)
    if LocalEntities[uNetId] then
        UnrenderLocalEntity(uNetId)
    end
end)

-- Unrender entities on resource stop
AddEventHandler("onResourceStop", function(resource)
    local _resource = GetCurrentResourceName()
    local entities = GlobalState.Entities

    for k, v in pairs(entities) do
        if v.createdBy == resource or resource == _resource then
            UnrenderLocalEntity(v.id)
        end
    end
end)

Citizen.CreateThread(function()
    while DebugRendering do
        DrawText3Ds(GetEntityCoords(PlayerPedId()), "Rendering Requested Entities: ".. #creatingEntities)
        Citizen.Wait(1)
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
