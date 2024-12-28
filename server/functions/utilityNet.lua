local NextId = 1

UtilityNet = UtilityNet or {}

-- options = {
--     resource = string (used internally)
--     replace = boolean (replace an already existing object, without creating a new one)
--     searchDistance = number (default 5.0, replace search distance)
--     door = boolean (if true will spawn the entity with door flag)
-- }

UtilityNet.CreateEntity = function(model, coords, options, callId)
    --#region Checks
    if not model or (type(model) ~= "string" and type(model) ~= "number") then
        error("Invalid model, got "..type(model).." expected string or number", 0)
    else
        if type(model) == "string" then
            model = GetHashKey(model)
        end
    end

    if not coords or type(coords) ~= "vector3" then
        error("Invalid coords, got "..type(coords).." expected vector3", 0)
    end

    options = options or {}
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityCreating", model, coords, options)

    -- EntityCreating event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then 
        return -1
    end
    --#endregion

    local entities = GlobalState.Entities
    local object = {
        id = NextId,
        model = model,
        coords = coords,
        slice = GetSliceFromCoords(coords),
        options = options,
        createdBy = options.resource or GetInvokingResource(),
    }

    table.insert(entities, object)
    GlobalState.Entities = entities

    RegisterEntityState(object.id)
    NextId = NextId + 1

    TriggerLatentClientEvent("Utility:Net:EntityCreated", -1, 5120, callId, object.id)
    return object.id
end

UtilityNet.DeleteEntity = function(uNetId)
    --#region Checks
    if type(uNetId) ~= "number" then
        error("Invalid uNetId, got "..type(uNetId).." expected number", 2)
        return
    end

    -- Invalid Id
    if uNetId == -1 then
        error("Invalid uNetId, got -1", 2)
        return
    end
    --#endregion

    --#region Event
    TriggerEvent("Utility:Net:EntityDeleting", uNetId)

    -- EntityDeleting event can be canceled, in that case we dont create the entity
    if WasEventCanceled() then
        return
    end
    --#endregion


    local entities = GlobalState.Entities

    for k,v in pairs(entities) do
        if v.id == uNetId then
            table.remove(entities, k)
            break
        end
    end

    GlobalState.Entities = entities

    TriggerLatentEventForListeners("Utility:Net:RequestDeletion", uNetId, 5120, uNetId)
    ClearEntityStates(uNetId) -- Clear states after trigger
end

local queues = {
    ModelsRenderDistance = {},
    Entities = {},
}

local function StartQueueUpdateLoop(bagkey)
    local queue = queues[bagkey]

    Citizen.CreateThread(function()
        while queue.updateLoop do
            -- Nothing added in the last 100ms
            if (GetGameTimer() - queue.lastInt) > 200 then
                local old = GlobalState[bagkey]
                local count = 0

                for k,v in pairs(old) do
                    -- Net id need to be updated
                    if queue[v.id] then
                        count = count + 1

                        -- Update values from queue to GlobalState
                        if queue[v.id].rotation then
                            v.options.rotation = queue[v.id].rotation
                        end

                        if queue[v.id].coords then
                            v.coords = queue[v.id].coords
                            v.slice = queue[v.id].slice
                        end
                    end
                end

                -- Refresh GlobalState
                GlobalState[bagkey] = old

                queues[bagkey].updateLoop = false
                queues[bagkey] = {}
            end
            Citizen.Wait(150)
        end
    end)
end

local function InsertValueInQueue(bagkey, id, value)
    -- If it is already in the queue with some values that need to be updated, we merge the 2 updates into 1
    if queues[bagkey][id] then
        queues[bagkey][id] = table.merge(queues[bagkey][id], value)
    else
        queues[bagkey][id] = value
    end

    queues[bagkey].lastInt = GetGameTimer()

    if not queues[bagkey].updateLoop then
        queues[bagkey].updateLoop = true
        StartQueueUpdateLoop(bagkey)
    end
end


UtilityNet.SetModelRenderDistance = function(model, distance)
    if type(model) == "string" then
        model = GetHashKey(model)
    end

    local _ = GlobalState.ModelsRenderDistance
    _[model] = distance
    GlobalState.ModelsRenderDistance = _
end

UtilityNet.SetEntityRotation = function(uNetId, newRotation)
    local source = source

    if type(newRotation) ~= "vector3" then
        error("Invalid rotation, got "..type(newRotation).." expected vector3", 2)
    end

    InsertValueInQueue("Entities", uNetId, {rotation = newRotation})

    -- Except caller since it will be already updated
    TriggerLatentEventForListenersExcept("Utility:Net:RefreshRotation", uNetId, 5120, source, uNetId, newRotation)

end

UtilityNet.SetEntityCoords = function(uNetId, newCoords)
    local source = source

    if type(newCoords) ~= "vector3" then
        error("Invalid coords, got "..type(newCoords).." expected vector3", 2)
    end

    InsertValueInQueue("Entities", uNetId, {coords = newCoords, slice = GetSliceFromCoords(newCoords)})
    
    -- Except caller since it will be already updated
    TriggerLatentEventForListenersExcept("Utility:Net:RefreshCoords", uNetId, 5120, source, uNetId, newCoords)
end

--#region Events
UtilityNet.RegisterEvents = function()
    RegisterNetEvent("Utility:Net:CreateEntity", function(callId, model, coords, options)
        UtilityNet.CreateEntity(model, coords, options, callId)
    end)
    
    RegisterNetEvent("Utility:Net:DeleteEntity", function(uNetId)
        UtilityNet.DeleteEntity(uNetId)
    end)
    
    RegisterNetEvent("Utility:Net:SetModelRenderDistance", function(model, distance)
        UtilityNet.SetModelRenderDistance(model, distance)
    end)

    RegisterNetEvent("Utility:Net:AttachToEntity", function(uNetId, object, params)
        local state = UtilityNet.State(uNetId)
        state.__attached = {
            object = object,
            params = params
        }
    end)

    RegisterNetEvent("Utility:Net:DetachEntity", function(uNetId, newCoords)
        local state = UtilityNet.State(uNetId)

        if state.__attached then
            -- Update entity coords
            UtilityNet.SetEntityCoords(uNetId, newCoords)
            state.__attached = nil
        end
    end)

    RegisterNetEvent("Utility:Net:SetEntityCoords", UtilityNet.SetEntityCoords)
    RegisterNetEvent("Utility:Net:SetEntityRotation", UtilityNet.SetEntityRotation)

    -- Clear all entities on resource stop (this will prevent also statebag leaks)
    AddEventHandler("onResourceStop", function(resource)
        if resource == GetCurrentResourceName() then
            for k,v in pairs(GlobalState.Entities) do
                --print("Stopped utility deleting", v.id)
                UtilityNet.DeleteEntity(v.id)
            end
        end
    end)
end
--#endregion

-- Exports for server native.lua
exports("CreateEntity", UtilityNet.CreateEntity)
exports("DeleteEntity", UtilityNet.DeleteEntity)
exports("SetModelRenderDistance", UtilityNet.SetModelRenderDistance)

exports("SetEntityCoords", UtilityNet.SetEntityCoords)
exports("SetEntityRotation", UtilityNet.SetEntityRotation)