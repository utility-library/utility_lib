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

    if Config.ESX_integration.main_switch then
        RegisterServerEvent("Utility:AddItem", function(item, amount)
            if Config.ESX_integration.AddItem then
                xPlayer.addInventoryItem(item, amount)
            end
        end)
    
        RegisterServerEvent("Utility:RemoveItem", function(item, amount)
            if Config.ESX_integration.RemoveItem then
                xPlayer.removeInventoryItem(item, amount)
            end
        end)
    
        ESX.RegisterServerCallback('Utility:GetItem', function(src, cb, item)
            if Config.ESX_integration.GetItem then
                cb(xPlayer.getInventoryItem(item))
            else
                cb(nil)
            end
        end)
    
        RegisterServerEvent("Utility:AddMoney", function(type, amount)
            if Config.ESX_integration.AddMoney then
                if type == "cash" then
                    xPlayer.addMoney(amount)
                else
                    xPlayer.addAccountMoney(type, amount)
                end
            end
        end)
    
        RegisterServerEvent("Utility:RemoveMoney", function(type, amount)
            if Config.ESX_integration.RemoveMoney then
                if type == "cash" then
                    xPlayer.removeMoney(amount)
                else
                    xPlayer.removeAccountMoney(type, amount)
                end
            end
        end)
    end
    
    if Config.DB_integration then
        ESX.RegisterServerCallback('Utility:GetDataFromDatabase', function(source, cb, settings)
            if settings.all then
                local data = MySQL.Sync.fetchAll("SELECT "..settings.select.." FROM utility_db_integration")
    
                cb(data)
            else
                local _data = {}
                
                for _,v1 in pairs(settings.where) do
                    for _,v2 in pairs(settings.equal) do
                        _data["@"..v1] = v2
                    end
                end
    
                local data = MySQL.Sync.fetchAll("SELECT "..settings.select.." FROM utility_db_integration WHERE "..settings.string:sub(1, -2), _data)
    
                cb(data)
            end
        end)
    
        ESX.RegisterServerCallback('Utility:SaveDataToDb', function(source, cb, settings)
            local _data = {}
            
            for _,v1 in pairs(settings.set) do
                for _,v2 in pairs(settings.equal) do
                    _data["@"..v1] = v2
                end
            end
    
            MySQL.Async.execute("INSERT INTO utility_db_integration SET "..settings.string:sub(1, -2), _data)
    
            cb(true)
        end)
    
        ESX.RegisterServerCallback('Utility:UpdateDataToDb', function(source, cb, settings)
            local _data = {}
            
            for _,v1 in pairs(settings.set.set_table) do
                for _,v2 in pairs(settings.set.equal_table) do
                    _data["@"..v1] = v2
                end
            end
    
            for _,v1 in pairs(settings.where.where_table) do
                for _,v2 in pairs(settings.where.equal_table) do
                    _data["@"..v1] = v2
                end
            end
    
            MySQL.Async.execute("UPDATE utility_db_integration SET "..settings.set.string:sub(1, -2).." WHERE "..settings.where.string:sub(1, -2), _data)
    
            cb(true)
        end)
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
    print("Added worker "..source.." for job "..job)
    print(json.encode(savedJobs))
end)

RegisterServerEvent("Utility:RefreshWorker", function(old_job, job)
    local _source = source
    local savedJobs = UtilityServer.Cache.SavedJobs 

    if savedJobs[job] == nil then 
        savedJobs[job] = {}
    end

    print(json.encode(savedJobs[old_job]))
    if savedJobs[old_job] ~= nil then
        for k,v in pairs(savedJobs[old_job]) do
            print(v, _source)
            if v == _source  then
                print(k)
                table.remove(savedJobs[old_job], k)
                break
            end
        end
    end

    savedJobs[job][#savedJobs[job] + 1] = _source
    print("Refreshed worker "..source.." for job "..job.." old job "..old_job)
    print(json.encode(savedJobs))
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