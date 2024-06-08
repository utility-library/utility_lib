local PlayersJobs = {}

RemoveFromJob = function(pId, oldJob)
    pId = tonumber(pId)
    --print("Removing "..pId.." to the job "..oldJob)

    if PlayersJobs[oldJob] ~= nil then
        for i=1, #PlayersJobs[oldJob] do
            if PlayersJobs[oldJob][i] == pId then
                table.remove(PlayersJobs[oldJob], i)
            end
        end
    end
end

AddToJob = function(pId, job)
    pId = tonumber(pId)
    --print("Adding "..pId.." to the job "..job)

    if not table.fexist(PlayersJobs, job) then
        PlayersJobs[job] = {pId}
    else
        table.insert(PlayersJobs[job], pId)
    end
end

GetDataForJob = function(job)
    return PlayersJobs[job]
end

LoadJobsAndRegisterCallbacks = function()
    if GetResourceState("qb-core") == "started" then
        QBCore = exports['qb-core']:GetCoreObject()

        QBCore.Functions.CreateCallback('Utility:GetJobData', function(source, cb, job)
            if not table.fexist(PlayersJobs, job) then
                cb({})
            else
                cb(PlayersJobs[job])
            end
        end)

        QBCore.Functions.CreateCallback('Utility:GetConfig', function(source, cb, job)
            cb(Config)
        end)

        -- Load Jobs
        for _, playerId in ipairs(GetPlayers()) do
            local Player = QBCore.Functions.GetPlayer(playerId)
                
            if Player then
                AddToJob(playerId, Player.job.name)     
            end
        end
    elseif GetResourceState("es_extended") == "started" then
        ESX = exports["es_extended"]:getSharedObject()

        ESX.RegisterServerCallback('Utility:GetJobData', function(src, cb, job)
            if not table.fexist(PlayersJobs, job) then
                cb({})
            else
                cb(PlayersJobs[job])
            end
        end)
        
        ESX.RegisterServerCallback('Utility:GetConfig', function(src, cb, job)
            cb(Config)
        end)

        -- Load Jobs
        for _, playerId in ipairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(playerId)

            if xPlayer then
                AddToJob(playerId, xPlayer.job.name)
            end
        end
    end
end

ListenForJobsChanges = function()
    if GetResourceState("es_extended") == "started" then
        AddEventHandler('esx:playerDropped', function(pId)
            local xPlayer = ESX.GetPlayerFromId(pId)
            RemoveFromJob(pId, xPlayer.job.name)
        end)
    
        -- On join
        AddEventHandler('esx:playerLoaded', function(pId, xPlayer)
            AddToJob(pId, xPlayer.job.name)
        end)
    
        -- On job change
        AddEventHandler('esx:setJob', function(pId, job, oldJob)
            RemoveFromJob(pId, oldJob.name)
            AddToJob(pId, job.name)
        end)
    elseif GetResourceState("qb-core") == "started" then
        AddEventHandler("QBCore:Client:OnPlayerUnload", function()
            local Player = QBCore.Functions.GetPlayer(source)
            RemoveFromJob(source, Player.job.name)
        end)

        AddEventHandler("QBCore:Server:PlayerLoaded", function()
            local Player = QBCore.Functions.GetPlayer(source)
            
            if Player then
                AddToJob(source, Player.job.name)
            end
        end)


        -- On job change
        
        -- IDK the trigger name, in the source code i didnt finded anything to track that data
        -- only that https://github.com/qbcore-framework/qb-core/blob/24317fcb4d872d77fc50a081a590da059f6f8ab6/server/player.lua#L190
        -- but is client side

        --[[AddEventHandler('esx:setJob', function(pId, job, oldJob)
            --print("Job changed")
            RemoveFromJob(pId, oldJob.name)
            AddToJob(pId, job.name)
        end)]]
    end
end


exports("GetDataForJob", GetDataForJob)