local queues = {}
local flushScheduled = false

local FlushClientEvents = function()
    local pending = queues

    queues = {}
    flushScheduled = false

    for player, queue in pairs(pending) do
        if queue.totalSize > Config.UtilityNetBatch.latentSize then
            TriggerLatentClientEvent("Utility:Net:Batch", player, -1, queue.entries)
        else
            TriggerClientEvent("Utility:Net:Batch", player, queue.entries)
        end
    end
end

local EnqueueForPlayers = function(players, coalesceId, name, ...)
    local entry = {name, select("#", ...), ...}
    local entrySize = #msgpack.pack(entry)

    for i = 1, #players do
        local player = tostring(players[i])
        local queue = queues[player]

        if not queue then
            queue = {entries = {}, entrySizes = {}, totalSize = 0, positionByCoalesceId = {}}
            queues[player] = queue
        end

        local position = coalesceId and queue.positionByCoalesceId[coalesceId]

        if position then
            queue.totalSize = queue.totalSize - queue.entrySizes[position] + entrySize
        else
            position = #queue.entries + 1
            queue.totalSize = queue.totalSize + entrySize

            if coalesceId then
                queue.positionByCoalesceId[coalesceId] = position
            end
        end

        queue.entries[position] = entry
        queue.entrySizes[position] = entrySize
    end

    if not flushScheduled and next(queues) then
        flushScheduled = true
        SetTimeout(Config.UtilityNetBatch.interval, FlushClientEvents)
    end
end

QueueClientEvent = function(players, name, ...)
    EnqueueForPlayers(players, nil, name, ...)
end

QueueCoalescedClientEvent = function(players, name, coalesceKey, ...)
    EnqueueForPlayers(players, name..":"..tostring(coalesceKey), name, ...)
end

AddEventHandler("playerDropped", function()
    queues[tostring(source)] = nil
end)
