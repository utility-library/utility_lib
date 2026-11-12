RegisterNetEvent("Utility:Net:Batch", function(entries)
    for i = 1, #entries do
        local entry = entries[i]

        TriggerEvent(entry[1], table.unpack(entry, 3, 2 + entry[2]))
    end
end)
