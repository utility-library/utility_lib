ESX = nil
local UtilityServer = {
    Cache = {
        SavedJobs = {},
        SavedxPlayer = {}
    }
}

local function RemoveFromJob(pId, oldJob)
    --print("Removing "..pId.." to the job "..oldJob)

    if UtilityServer.Cache.SavedJobs[oldJob] ~= nil then
        for i=1, #UtilityServer.Cache.SavedJobs[oldJob] do
            if UtilityServer.Cache.SavedJobs[oldJob][i] == pId then
                table.remove(UtilityServer.Cache.SavedJobs[oldJob], i)
            end
        end
    end
end

local function AddToJob(pId, job)
    --print("Adding "..pId.." to the job "..job)

    if not table.fexist(UtilityServer.Cache.SavedJobs, job) then
        UtilityServer.Cache.SavedJobs[job] = {pId}
    else
        table.insert(UtilityServer.Cache.SavedJobs[job], pId)
    end
end

local resName = GetCurrentResourceName()
AddEventHandler("onResourceStart", function(resource)
    if resName == resource then
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(10)
        end

        ESX.RegisterServerCallback('Utility:GetJobData', function(src, cb, job)
            if not table.fexist(UtilityServer.Cache.SavedJobs, job) then
                cb({})
            else
                cb(UtilityServer.Cache.SavedJobs[job])
            end
        end)
        
        ESX.RegisterServerCallback('Utility:GetConfig', function(src, cb, job)
            cb(Config)
        end)

        -- Jobs
        local players = ESX.GetPlayers()

        for i=1, #players do
            --print("On start check")
            local xPlayer = ESX.GetPlayerFromId(players[i])
            AddToJob(players[i], xPlayer.job.name)
        end
    end
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

-- Job
    -- On quit
    AddEventHandler('esx:playerDropped', function(pId)
        local xPlayer = ESX.GetPlayerFromId(pId)
        RemoveFromJob(pId, xPlayer)
    end)

    -- On join
    AddEventHandler('esx:playerLoaded', function(pId, xPlayer)
        --print("Player loaded")
        AddToJob(pId, xPlayer.job.name)
    end)

    -- On job change
    AddEventHandler('esx:setJob', function(pId, job, oldJob)
        --print("Job changed")
        RemoveFromJob(pId, oldJob.name)
        AddToJob(pId, job.name)
    end)