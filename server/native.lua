_G["ESX"] = nil

local old_RegisterServerEvent = RegisterServerEvent
RegisterServerEvent = function(eventName, eventRoutine, no_auto_prepare)
    old_RegisterServerEvent(eventName)

    if no_auto_prepare == nil then
        AddEventHandler(eventName, function(...)
            _source = source
            xPlayer = ESX.GetPlayerFromId(_source)

            eventRoutine(...)
        end)
    elseif no_auto_prepare then
        AddEventHandler(eventName, eventRoutine)
    end
end

StartESX = function(triggerName)
    TriggerEvent(triggerName or 'esx:getSharedObject', function(obj) ESX = obj end)
end

ShowNotification = function(source, msg)
    TriggerClientEvent('esx:showNotification', source, msg)
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