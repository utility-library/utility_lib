RenderLocalEntity = function(uNetId, coords, model, options)
    options = options or {}
    local obj = 0

    if options.replace then
        local attempts = 0
        
        while attempts < 5 and not DoesEntityExist(obj) do
            obj = GetClosestObjectOfType(coords, options.searchDistance or 5.0, model)
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
        -- If already exists use that (to also allow for re-rendering of map placed objects)
        obj = GetClosestObjectOfType(coords, 1.0, model)

        if obj == 0 then
            obj = CreateObject(model, coords, false)
        else
            -- If found keep it alive on unrender
            Entity(obj).state.keepAlive = true
        end
    end
    
    LocalEntities[uNetId] = obj

    TriggerEvent("Utility:Net:OnRender", uNetId, obj, model)
end

UnrenderLocalEntity = function(uNetId)
    local entity = UtilityNet.GetEntityFromUNetId(uNetId)
    TriggerEvent("Utility:Net:OnUnrender", uNetId, entity, GetEntityModel(entity))

    Citizen.Wait(1)

    if DoesEntityExist(LocalEntities[uNetId]) then
        local state = Entity(LocalEntities[uNetId]).state

        if not state.keepAlive then
            if state.preserved then
                SetEntityAsNoLongerNeeded(LocalEntities[uNetId])
            else
                DeleteEntity(LocalEntities[uNetId])
            end
        end
    end

    LocalEntities[uNetId] = nil
end

StartUtilityNetRenderLoop = function()
    CreateLoop(function(loopId)
        local entities = GlobalState.Entities
        local modelsRenderDistance = GlobalState.ModelsRenderDistance

        if #entities > 0 then
            while not HasCollisionLoadedAroundEntity(player) or not NetworkIsPlayerActive(PlayerId()) do
                Citizen.Wait(100)
            end
    
            local coords = GetEntityCoords(player)

            for _, v in pairs(entities) do
                local uNetId = v.id
                local entity = UtilityNet.GetEntityFromUNetId(uNetId)
    
                if #(v.coords - coords) < (modelsRenderDistance[v.model] or 50.0) then
                    if not entity or not DoesEntityExist(entity) then
                        if entity and not DoesEntityExist(entity) then
                            --print("Before rendering unrender old entity", uNetId)
                            UnrenderLocalEntity(uNetId)
                        end
    
                        --print("Render", uNetId)
                        RenderLocalEntity(uNetId, v.coords, v.model, v.options)
                    end
                else
                    if entity then
                        UnrenderLocalEntity(uNetId)
                    end
                end
            end
        end
    end, Config.UpdateCooldown)
end

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