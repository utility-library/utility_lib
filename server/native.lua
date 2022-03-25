_G["ESX"] = nil

--// Improved/Custom Native //--
    local old_RegisterServerEvent = RegisterServerEvent
    RegisterServerEvent = function(eventName, eventRoutine, no_auto_prepare)
        old_RegisterServerEvent(eventName)

        if no_auto_prepare then
            AddEventHandler(eventName, eventRoutine)
        else
            AddEventHandler(eventName, function(...)
                _source = source

                if GetResourceState("es_extended") == "started" then
                    if ESX then
                        xPlayer = ESX.GetPlayerFromId(_source)    
                    end
                end

                eventRoutine(...)
            end)
        end
    end

    StartESX = function(triggerName)
        TriggerEvent(triggerName or 'esx:getSharedObject', function(obj) ESX = obj end)
    end
    StartQB = function(triggerName)
        QBCore = exports['qb-core']:GetCoreObject()
    end

    ShowNotification = function(source, msg, type)
        if GetResourceState("qb-core") == "started" then
            TriggerClientEvent('QBCore:Notify', source, msg, type)
        elseif GetResourceState("es_extended") == "started" then
            TriggerClientEvent('esx:showNotification', source, msg)
        end
    end

    CreateLoop = function(_function, tickTime)
        Citizen.CreateThread(function()
            local active = true
            local NoAsync = {}
            _break = function()
                active = false
            end

            LoopThread = function(id, time, _function)
                if NoAsync[id] == nil then
                    NoAsync[id] = {a = true, b = false}
                end

                if NoAsync[id].a then
                    if not NoAsync[id].b then
                        NoAsync[id].b = true
                        Citizen.SetTimeout(time, function()
                            _function()
                            NoAsync[id].b = false
                        end)
                    end
                end
            end

            TaskBack = function(id, _function)
                LoopThread(id, 5000, function()
                    _function()
                end)
            end

            TaskSlow = function(id, _function)
                LoopThread(id, 1000, function()
                    _function()
                end)
            end

            TaskFast = function(id, _function)
                LoopThread(id, 500, function()
                    _function()
                end)
            end

            TaskExtrafast = function(id, _function)
                LoopThread(id, 5, function()
                    _function()
                end)
            end

            StopLoopThread = function(id)
                NoAsync[id].a = false
            end

            ResumeLoopThread = function(id)
                NoAsync[id].a = true
            end

            while active do
                _function()
                Citizen.Wait(tickTime or 5)
            end
        end)
    end

--// Player //--
    -- Item
        AddItem = function(item, amount)
            xPlayer.addInventoryItem(item, amount)
        end

        RemoveItem = function(item, amount)
            xPlayer.removeInventoryItem(item, amount)
        end

        GetItem = function(item)
            return xPlayer.getInventoryItem(item)
        end

        HaveItem = function(item)
            return xPlayer.getInventoryItem(item).count > 0
        end

        HaveItemQuantity = function(item, quantity)
            return xPlayer.getInventoryItem(item).count > quantity
        end

    -- Money
        AddMoney = function(type, amount)
            if type == "cash" then
                xPlayer.addMoney(amount)
            else
                xPlayer.addAccountMoney(type, amount)
            end
        end

        RemoveMoney = function(type, amount)
            if type == "cash" then
                xPlayer.removeMoney(amount)
            else
                xPlayer.removeAccountMoney(type, amount)
            end
        end

        HaveMoney = function(type, amount)
            if type == "cash" then
                return xPlayer.getMoney() >= amount
            else
                return xPlayer.getAccount(type).money >= amount
            end
        end

--// MySQL //--
    StartMySQL = function()
        MySQL = {
            Async = {},
            Sync = {},
        }
        
        local function safeParameters(params)
            if nil == params then
                return {[''] = ''}
            end
        
            assert(type(params) == "table", "A table is expected")
        
            if next(params) == nil then
                return {[''] = ''}
            end
        
            return params
        end

        function MySQL.Sync.execute(query, params)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            local res = 0
            local finishedQuery = false
            exports['mysql-async']:mysql_execute(query, safeParameters(params), function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Sync.fetchAll(query, params)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            local res = {}
            local finishedQuery = false
            exports['mysql-async']:mysql_fetch_all(query, safeParameters(params), function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Sync.fetchScalar(query, params)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            local res = ''
            local finishedQuery = false
            exports['mysql-async']:mysql_fetch_scalar(query, safeParameters(params), function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Sync.insert(query, params)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            local res = 0
            local finishedQuery = false
            exports['mysql-async']:mysql_insert(query, safeParameters(params), function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Sync.store(query)
            assert(type(query) == "string", "The SQL Query must be a string")
        
            local res = -1
            local finishedQuery = false
            exports['mysql-async']:mysql_store(query, function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Sync.transaction(querys, params)
            local res = 0
            local finishedQuery = false
            exports['mysql-async']:mysql_transaction(querys, params, function (result)
                res = result
                finishedQuery = true
            end)
            repeat Citizen.Wait(0) until finishedQuery == true
            return res
        end

        function MySQL.Async.execute(query, params, func)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            exports['mysql-async']:mysql_execute(query, safeParameters(params), func)
        end

        function MySQL.Async.fetchAll(query, params, func)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            exports['mysql-async']:mysql_fetch_all(query, safeParameters(params), func)
        end

        function MySQL.Async.fetchScalar(query, params, func)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            exports['mysql-async']:mysql_fetch_scalar(query, safeParameters(params), func)
        end
        
        function MySQL.Async.insert(query, params, func)
            assert(type(query) == "string" or type(query) == "number", "The SQL Query must be a string")
        
            exports['mysql-async']:mysql_insert(query, safeParameters(params), func)
        end
        
        function MySQL.Async.store(query, func)
            assert(type(query) == "string", "The SQL Query must be a string")
        
            exports['mysql-async']:mysql_store(query, func)
        end
        
        function MySQL.Async.transaction(querys, params, func)
            return exports['mysql-async']:mysql_transaction(querys, params, func)
        end
        
        function MySQL.ready(callback)
            Citizen.CreateThread(function ()
                while GetResourceState('mysql-async') ~= 'started' do
                    Citizen.Wait(0)
                end
                while not exports['mysql-async']:is_ready() do
                    Citizen.Wait(0)
                end
                callback()
            end)
        end    
    end

    ExecuteSql = function(query, params)
        if MySQL == nil then
            StartMySQL()
        end

        if string.find(query, "SELECT") then
            return MySQL.Sync.fetchAll(query, params)
        elseif string.find(query, "INSERT") or string.find(query, "UPDATE") then
            MySQL.Sync.execute(query, params)
        end
    end

--// Society //--
    -- Item
        SocietyAddItem = function(society, item, amount)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            TriggerEvent('esx_addoninventory:getSharedInventory', society, function(deposit)
                deposit.addItem(item, amount)
            end)
        end

        SocietyRemoveItem = function(society, item, amount)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            TriggerEvent('esx_addoninventory:getSharedInventory', society, function(deposit)
                deposit.removeItem(item, amount)
            end)
        end

        SocietyGetItem = function(society, item)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            local _return = nil

            TriggerEvent('esx_addoninventory:getSharedInventory', society, function(deposit)
                _return = deposit.getItem(item)
            end)

            while _return == nil do
                Citizen.Wait(1)
            end

            return _return
        end

        SocietyHaveItem = function(society, item)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            local _return = nil

            TriggerEvent('esx_addoninventory:getSharedInventory', society, function(deposit)
                local inventoryItem = deposit.getItem(item).count
                
                _return = inventoryItem > 0
            end)

            while _return == nil do
                Citizen.Wait(1)
            end

            return _return
        end

        SocietyHaveItemQuantity = function(society, item, quantity)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            local _return = nil

            TriggerEvent('esx_addoninventory:getSharedInventory', society, function(deposit)
                local inventoryItem = deposit.getItem(item).count
                
                _return = inventoryItem > quantity
            end)

            while _return == nil do
                Citizen.Wait(1)
            end

            return _return
        end

    -- Money
        SocietyAddMoney = function(society, amount)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
                account.addMoney(amount)
            end)
        end

        SocietyRemoveMoney = function(society, amount)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
                account.removeMoney(amount)
            end)
        end

        SocietyHaveMoney = function(society, amount)
            if not string.find(society, "society_") then
                society = "society_"..society
            end

            local have = nil
            TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
                have = account.money >= amount
            end)

            while have == nil do
                Citizen.Wait(1)
            end

            return have
        end

--// Misc //--
    printd = function(_table, advanced)
        if advanced then
            local printTable_cache = {}

            local function sub_printTable(t, indent)
                if (printTable_cache[tostring(t)]) then
                    print(indent.."*"..tostring(t))
                else
                    printTable_cache[tostring(t)] = true
                    if (type(t) == "table") then
                        for pos,val in pairs(t) do
                            if (type(val) == "table") then
                                print(indent.."["..pos.."] => "..tostring(t).. " {" )
                                    sub_printTable(val, indent..string.rep(" ", string.len(pos)+8))
                                print(indent..string.rep(" ", string.len(pos)+6 ).."}")
                            elseif (type(val) == "string") then
                                print(indent.."["..pos.."] => \"" .. val .. "\"")
                            else
                                print(indent.."["..pos.."] => "..tostring(val))
                            end
                        end
                    else
                        print(indent..tostring(t))
                    end
                end
            end
        
            if (type(_table) == "table") then
                print(tostring(_table).." {")
                sub_printTable(_table, "  ")
                print("}")
            else
                developer("^1Error^0", "error dumping table ".._table.." why isnt a table", "")
            end
        else
            if type(_table) == "table" then
                print(json.encode(_table, {indent = true}))
            else
                developer("^1Error^0", "error dumping table ".._table.." why isnt a table", "")
            end
        end
    end

    local string_gsub = string.gsub
    string.multigsub = function(string, table, new)
        if type(table) then
            for i=1, #table do
                string = string_gsub(string, table[i], new[i])
            end
        else
            for i=1, #table do
                string = string_gsub(string, table[i], new)
            end
        end

        return string
    end

    table.fexist = function(_table, field)
        _table = _table[field]
        if not _table then
            return false
        else
            return true
        end
    end

    local table_remove = table.remove
    table.remove = function(_table, index, onlyfirst)
        if type(index) == "number" then
            table_remove(_table, index)
        elseif type(index) == "string" then
            for k, v in pairs(_table) do
                if k == index then
                    _table[k] = nil -- Can be bugged, probably in future update will be changed with a empty table => {}

                    if onlyfirst then
                        break
                    end
                end
            end
        end
    end

    table.empty = function(_table)
        return next(_table) == nil
    end

    -- I dont think this works, i dont have learned and tested so much metatable of lua
    table.clone = function(_table)
        _table.metatable = {__index = _table}

        local _result = {}
        setmetatable(_result, _table.metatable)

        return _result
    end
