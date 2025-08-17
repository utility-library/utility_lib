--// Improved/Custom Native //--
    StartESX = function(triggerName)
        ESX = exports["es_extended"]:getSharedObject()
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
            _break = function()
                active = false
            end

            while active do
                _function()
                Citizen.Wait(tickTime or 5)
            end
        end)
    end

--// Player //--
    -- Item
        AddItem = function(source, item, amount, metadata, slot)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                xPlayer.addInventoryItem(item, amount, metadata, slot)
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                xPlayer.Functions.AddItem(item, amount, slot, metadata)
            end
        end

        RemoveItem = function(source, item, amount, metadata, slot)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                xPlayer.removeInventoryItem(item, amount, metadata, slot)
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                xPlayer.Functions.RemoveItem(item, amount, slot, metadata)
            end
        end

        GetItem = function(source, ...)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                return xPlayer.getInventoryItem(...)
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                return xPlayer.Functions.GetItemByName(...)
            end
        end

        HaveItem = function(source, ...)
            local item = GetItem(source, ...)
            
            if not item then
                return false
            end

            if ESX then
                return item.count > 0
            else
                return item.amount > 0
            end
        end

        HaveItemQuantity = function(source, item, quantity)
            local item = GetItem(source, item)
            
            if not item then
                return false
            end

            if ESX then
                return item.count > quantity 
            else
                return item.amount > quantity 
            end
        end

    -- Money
        AddMoney = function(source, type, ...)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                if type == "cash" then
                    xPlayer.addMoney(...)
                else
                    xPlayer.addAccountMoney(type, ...)
                end
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                xPlayer.Functions.AddMoney(type, ...)
            end
        end

        RemoveMoney = function(source, type, ...)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                if type == "cash" then
                    xPlayer.removeMoney(...)
                else
                    xPlayer.removeAccountMoney(type, ...)
                end
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                xPlayer.Functions.RemoveMoney(type, ...)
            end
        end

        HaveMoney = function(source, type, amount)
            if ESX then
                xPlayer = ESX.GetPlayerFromId(source)
                if type == "cash" then
                    return xPlayer.getMoney(type) >= amount
                else
                    return xPlayer.getAccount(type).money >= amount
                end
            else
                xPlayer = QBCore.Functions.GetPlayer(source)
                
                return xPlayer.Functions.GetMoney(type) >= amount
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
        return _table[field] ~= nil
    end

    local table_remove = table.remove
    table.remove = function(_table, index, onlyfirst)
        if type(index) == "number" then
            return table_remove(_table, index)
        elseif type(index) == "string" then
            for k, v in pairs(_table) do
                if k == index then
                    _table[k] = nil -- Can be bugged, probably in future update will be changed with a empty table

                    if onlyfirst then
                        return k
                    end
                end
            end
        else
            return table_remove(_table)
        end
    end

    ---Check if a table is empty.
    ---@param t table
    ---@return boolean
    table.empty = function(t)
        return next(t) == nil
    end

    ---Internal usage: Inserts a value into a table at a given key, or appends to the end if the key is a number.
    ---@param t table
    ---@param k any
    ---@param v any
    local table_insert = function(t, k, v)
        if type(k) == "number" then
            table.insert(t, v)
        else
            t[k] = v
        end
    end

    ---Merges two tables together, if the same key is found in both tables the second table takes precedence.
    ---@param t1 table
    ---@param t2 table
    ---@return table
    table.merge = function(t1, t2)
        ---@type table
        local result = table.clone(t1)

        for k, v in pairs(t2) do
            table_insert(result, k, v)
        end

        return result
    end


    ---Checks if the given value exists in the table, if a function is given it test it on each value until it returns true.
    ---@param t table
    ---@param value any|fun(value: any): boolean
    ---@return boolean
    table.includes = function(t, value)
        if type(value) == "function" then
            for _, v in pairs(t) do
                if value(v) then
                    return true
                end
            end
        else
            for _, v in pairs(t) do
                if value == v then
                    return true
                end
            end
        end

        return false
    end

    ---Filters a table using a given filter, which can be an another table or a function.
    ---@param t table
    ---@param filter table|fun(k: any, v: any): boolean
    ---@return table
    table.filter = function(t, filter)
        local result = {}

        if type(filter) == "function" then
            -- returns true.
            for k, v in pairs(t) do
                if filter(k, v) then
                    table_insert(result, k, v)
                end
            end
        elseif type(filter) == "table" then
            for k, v in pairs(t) do
                if table.includes(filter, v) then
                    table_insert(result, k, v)
                end
            end
        end

        return result
    end

    ---Searches a table for the given value and returns the key and value if found.
    ---@param t table
    ---@param value any|fun(value: any): boolean
    ---@return any
    table.find = function(t, value)
        if type(value) == "function" then
            for k, v in pairs(t) do
                if value(v) then
                    return k, v
                end
            end
        else
            for k, v in pairs(t) do
                if value == v then
                    return k, v
                end
            end
        end
    end

    ---Returns a table with all keys of the given table.
    ---@param t table
    ---@return table
    table.keys = function(t)
        local keys = {}    
        for k, _ in pairs(t) do
            table.insert(keys, k)
        end

        return keys
    end

    ---Returns a table with all values of the given table.
    ---@param t table
    ---@return table
    table.values = function(t)
        local values = {}
        
        for _, v in pairs(t) do
            table.insert(values, v)
        end
        
        return values
    end

    -- Uses table.clone for fast shallow copying (memcpy) before checking and doing actual deepcopy for nested tables
    -- Handles circular references via seen table
    -- Significantly faster (~50%) than doing actual deepcopy for flat or lightly-nested structures
    ---@param orig table
    ---@return table
    table.deepcopy = function(orig, seen)
        if type(orig) ~= "table" then return orig end
        seen = seen or {}
        if seen[orig] then return seen[orig] end

        local copy = table.clone(orig)
        seen[orig] = copy

        for k, v in next, orig do
            if type(v) == "table" then
                copy[k] = table.deepcopy(v, seen)
            end
        end

        return copy
    end

    math.round = function(number, decimals)
        local _ = 10 ^ decimals
        return math.floor((number * _) + 0.5) / (_)
    end

    -- https://www.gamedev.net/tutorials/programming/general-and-gameplay-programming/inverse-lerp-a-super-useful-yet-often-overlooked-function-r5230/
    math.lerp = function(start, _end, perc)
        return start + (_end - start) * perc
    end

    math.invlerp = function(start, _end, value)
        return (value - start) / (_end - start)
    end

    GetDataForJob = function(job)
        return exports["utility_lib"]:GetDataForJob(job)
    end

    quat2euler = function(q)
        -- roll (x-axis rotation)
        local sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
        local cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
        local roll = math.atan2(sinr_cosp, cosr_cosp);
    
        -- pitch (y-axis rotation)
        local sinp = math.sqrt(1 + 2 * (q.w * q.y - q.x * q.z));
        local cosp = math.sqrt(1 - 2 * (q.w * q.y - q.x * q.z));
        local pitch = 2 * math.atan2(sinp, cosp) - math.pi / 2;
    
        -- yaw (z-axis rotation)
        local siny_cosp = 2 * (q.w * q.z + q.x * q.y);
        local cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
        local yaw = math.atan2(siny_cosp, cosy_cosp);
    
        return vec3(math.deg(roll), math.deg(pitch), math.deg(yaw));
    end

    GenerateMatrix = function(pos, rot)
        local rx, ry, rz = math.rad(rot.x), math.rad(rot.y), math.rad(rot.z)
    
        -- Precompute
        local cosX, sinX = math.cos(rx), math.sin(rx)
        local cosY, sinY = math.cos(ry), math.sin(ry)
        local cosZ, sinZ = math.cos(rz), math.sin(rz)
    
        local mrx = mat3(
            vec3(1, 0, 0),
            vec3(0, cosX, -sinX),
            vec3(0, sinX, cosX)
        )
        
        local mry = mat3(
            vec3(cosY, 0, sinY),
            vec3(0, 1, 0),
            vec3(-sinY, 0, cosY)
        )
    
        local mrz = mat3(
            vec3(cosZ, -sinZ, 0),
            vec3(sinZ, cosZ, 0),
            vec3(0, 0, 1)
        )
    
        local rotationMatrix = mrx * mry * mrz
    
        -- Construct the final transform matrix
        local transformMatrix = mat4(
            vec4(rotationMatrix[1].x, rotationMatrix[2].x, rotationMatrix[3].x, 0),
            vec4(rotationMatrix[1].y, rotationMatrix[2].y, rotationMatrix[3].y, 0),
            vec4(rotationMatrix[1].z, rotationMatrix[2].z, rotationMatrix[3].z, 0),
            vec4(pos.x, pos.y, pos.z, 1)
        )
    
        return transformMatrix
    end
    
    GetOffsetFromPositionInWorldCoords = function(pos, rot, offset)
        local m = GenerateMatrix(pos, rot)
        return m * offset
    end
--// Slices //--
    local sliceSize = 100.0
    local slicesLength = 8100
    local sliceCollumns = slicesLength / sliceSize

    function GetSliceColRowFromCoords(coords)
        local row = math.floor((coords.x) / sliceSize)
        local col = math.floor((coords.y) / sliceSize)

        return col, row
    end

    function GetWorldCoordsFromSlice(slice)
        local col = math.floor(slice / sliceCollumns)
        local row = slice % sliceCollumns

        return vec3((row * sliceSize), (col * sliceSize), 0.0)
    end

    function GetSliceIdFromColRow(col, row)
        return math.floor(col * sliceCollumns + row)
    end

    function GetSliceFromCoords(pos)
        local col, row = GetSliceColRowFromCoords(pos)

        return GetSliceIdFromColRow(col, row)
    end

    function GetSurroundingSlices(slice)
        local top = slice - sliceCollumns
        local bottom = slice + sliceCollumns

        local right = slice - 1
        local left = slice + 1

        local topright = slice - sliceCollumns - 1
        local topleft = slice - sliceCollumns + 1
        local bottomright = slice + sliceCollumns - 1
        local bottomleft = slice + sliceCollumns + 1

        return {math.floor(top), math.floor(bottom), math.floor(left), math.floor(right), math.floor(topright), math.floor(topleft), math.floor(bottomright), math.floor(bottomleft)}
    end

--// UtilityNet //--
local CreatedEntities = {}
UtilityNet = {}

UtilityNet.ForEachEntity = function(fn, slices)
    local _entities = UtilityNet.GetEntities(slices)
    local n = 0
    
    if _entities then
        -- Manual pairs loop for performance
        local _k, _v = next(_entities)

        while _k do
            local k,v = next(_v)

            while k do
                n = n + 1
                local ret = fn(v, k)
    
                if ret ~= nil then
                    return ret
                end
                k,v = next(_entities[_k], k)
            end

            _k, _v = next(_entities, _k)
        end
    end
end

UtilityNet.CreateEntity = function(model, coords, options)
    local id = exports["utility_lib"]:CreateEntity(model, coords, options)
    table.insert(CreatedEntities, id)

    return id
end

UtilityNet.SetEntityModel = function(uNetId, model)
    return exports["utility_lib"]:SetEntityModel(uNetId, model)
end

UtilityNet.DeleteEntity = function(uNetId)
    for k, v in pairs(CreatedEntities) do
        if v == uNetId then
            table.remove(CreatedEntities, k)
            break
        end
    end

    return exports["utility_lib"]:DeleteEntity(uNetId)
end


UtilityNet.AttachToEntity = function(uNetId, to, boneIdOrName, pos, rot, useSoftPinning, collision, rotationOrder, syncRot)
    local params = {boneServer = boneIdOrName, pos = pos, rot = rot, useSoftPinning = useSoftPinning, collision = collision, rotationOrder = rotationOrder, syncRot = syncRot}
    params.isUtilityNet = true

    return exports["utility_lib"]:AttachTo(uNetId, to, params)
end

UtilityNet.AttachToNetId = function(uNetId, netId, bone, pos, rot, useSoftPinning, collision, rotationOrder, syncRot)
    local params = {bone = bone, pos = pos, rot = rot, useSoftPinning = useSoftPinning, collision = collision, rotationOrder = rotationOrder, syncRot = syncRot}

    return exports["utility_lib"]:AttachTo(uNetId, netId, params)
end

UtilityNet.DetachEntity = function(uNetId)
    return exports["utility_lib"]:DetachEntity(uNetId)
end

-- Returns the slice the entity is in
UtilityNet.InternalFindFromNetId = function(uNetId)
    return exports["utility_lib"]:InternalFindFromNetId(uNetId)
end

UtilityNet.DoesUNetIdExist = function(uNetId)
    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    return entity or false
end

UtilityNet.GetEntityCoords = function(uNetId)
    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    if entity then
        return entity.coords
    end
end

UtilityNet.GetEntityRotation = function(uNetId)
    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    if entity then
        return entity.options.rotation
    end
end

UtilityNet.GetEntityModel = function(uNetId)
    local entity = UtilityNet.InternalFindFromNetId(uNetId)

    if entity then
        return entity.model
    end
end

UtilityNet.GetEntities = function(slices)
    return exports["utility_lib"]:GetEntities(slices)
end

UtilityNet.SetModelRenderDistance = function(model, distance)
    return exports["utility_lib"]:SetModelRenderDistance(model, distance)
end

UtilityNet.SetEntityCoords = function(uNetId, newCoords, skipPositionUpdate)
    return exports["utility_lib"]:SetEntityCoords(uNetId, newCoords, skipPositionUpdate)
end

UtilityNet.SetEntityRotation = function(uNetId, newRotation, skipRotationUpdate)
    return exports["utility_lib"]:SetEntityRotation(uNetId, newRotation, skipRotationUpdate)
end

UtilityNet.DetachEntity = function(uNetId)
    TriggerEvent("Utility:Net:DetachEntity", uNetId)
end

local getValueAsStateTable = nil
getValueAsStateTable = function(id, baseKey, depth)
    depth = depth or {}

    local getCurrentTable = function()
        local baseTable = exports["utility_lib"]:GetEntityStateValue(id, baseKey)

        -- Dive into table
        for k,v in pairs(depth) do
            baseTable = baseTable[v]
        end

        return baseTable
    end

    return setmetatable({
        __internal_statetable = true,
        raw = function(self)
            return getCurrentTable()
        end
    }, {
        -- Iterators
        __pairs = function(self)
            return pairs(getCurrentTable())
        end,

        __ipairs = function(self)
            return ipairs(getCurrentTable())
        end,

        __len = function(self)
            return #getCurrentTable()
        end,

        __index = function(_, k)
            local currentTable = getCurrentTable()

            if type(currentTable[k]) == "table" then
                -- Clone the table to dont mess up the current depth table
                local clonedDepth = table.clone(depth)
                table.insert(clonedDepth, k)

                -- Generate another state table but more in depth
                return getValueAsStateTable(id, baseKey, clonedDepth)
            else
                return currentTable[k]
            end
        end,
        __newindex = function(_, k, v)
            local baseTable = exports["utility_lib"]:GetEntityStateValue(id, baseKey)
            local currentTable = baseTable

            -- Dive into table
            for k,v in pairs(depth) do
                currentTable = currentTable[v]
            end
    
            -- Set
            currentTable[k] = v
            
            -- Update state table
            exports["utility_lib"]:SetEntityStateValue(id, baseKey, baseTable)
        end
    })
end

UtilityNet.AddStateBagChangeHandler = function(uNetId, func)
    return AddEventHandler("Utility:Net:UpdateStateValue", function(s_uNetId, key, value)
        if uNetId == s_uNetId then
            func(key, value)
        end
    end)
end

UtilityNet.RemoveStateBagChangeHandler = function(eventData)
    if eventData and eventData.key and eventData.name then
        RemoveEventHandler(eventData)
    end
end

UtilityNet.State = function(id)
    if not id then
        error("UtilityNet.State: id is required, got nil", 2)
    end

    local state = setmetatable({
        raw = function(self)
            return exports["utility_lib"]:GetEntityStateValue(id)
        end
    }, {
        __index = function(_, k)
            local value = exports["utility_lib"]:GetEntityStateValue(id, k)

            if type(value) == "table" then
                return getValueAsStateTable(id, k, {})
            else
                return value
            end
        end,

        __newindex = function(_, k, v)
            -- If the value is a state table get the raw table (without metatable)
            if type(v) == "table" and v.__internal_statetable then
                v = v:raw()
            end

            exports["utility_lib"]:SetEntityStateValue(id, k, v)
        end
    })

    return state
end

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for k, v in pairs(CreatedEntities) do
            exports["utility_lib"]:DeleteEntity(v)
        end
    end
end)
