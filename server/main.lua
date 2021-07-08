ESX = nil
local UtilityServer = {
    Cache = {
        SavedJobs = {}
    }
}

Citizen.CreateThread(function()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(10)
    end

    ESX.RegisterServerCallback('Utility:GetJobData', function(src, cb, job)
        if UtilityServer.Cache.SavedJobs[job] == nil then
            cb({})
        else
            cb(UtilityServer.Cache.SavedJobs[job])
        end
    end)
    
    ESX.RegisterServerCallback('Utility:GetConfig', function(src, cb, job)
        cb(Config)
    end)
end)

RegisterServerEvent("Utility:SyncEvent", function(event, whitelist, ...)
    if type(whitelist) == "table" then
        for i=1,#whitelist do
            TriggerClientEvent(event, whitelist[i], ...)
        end
    elseif type(whitelist) == "number" then
        TriggerClientEvent(event, whitelist, ...)
    else
        TriggerClientEvent(event, -1, ...)
    end
end)

RegisterServerEvent("Utility:AddWorker", function(job)
    local _source = source
    local savedJobs = UtilityServer.Cache.SavedJobs 

    if savedJobs[job] == nil then 
        savedJobs[job] = {}
    end

    savedJobs[job][#savedJobs[job] + 1] = _source
    --print("Added worker "..source.." for job "..job)
    --print(json.encode(savedJobs))
end)

RegisterServerEvent("Utility:RefreshWorker", function(old_job, job)
    local _source = source
    local savedJobs = UtilityServer.Cache.SavedJobs 

    if savedJobs[job] == nil then 
        savedJobs[job] = {}
    end

    --print(json.encode(savedJobs[old_job]))
    if savedJobs[old_job] ~= nil then
        for k,v in pairs(savedJobs[old_job]) do
            --print(v, _source)
            if v == _source  then
                --print(k)
                table.remove(savedJobs[old_job], k)
                break
            end
        end
    end

    savedJobs[job][#savedJobs[job] + 1] = _source
    --print("Refreshed worker "..source.." for job "..job.." old job "..old_job)
    --print(json.encode(savedJobs))
end)

AddEventHandler('playerDropped', function()
    local _source = source
    local xPlayer = (ESX.GetPlayerFromId(_source)).job.name

    local savedJobs = UtilityServer.Cache.SavedJobs 

    if savedJobs[xPlayer] ~= nil then
        for k,v in pairs(savedJobs[xPlayer]) do
            if v == _source then
                table.remove(savedJobs[xPlayer], k)
                break
            end
        end
    end
end)
