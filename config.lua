Config = {}

Config.SecondJob = "" -- If you have a second job insert it here

-- Marker
Config.UpdateCooldown = 500 -- (default: 500ms) This is the time when the position/distance of any marker will update










------------------------------------------------------------------------------------------------------------------------------
-- THIS IS ONLY THE TRIGGER, IF YOU DISABLE IT YOU CAN STILL USE THE NATIVE BUT DONT CHANGE/GIVE ANYTHING (DONT GIVE ERROR) --
------------------------------------------------------------------------------------------------------------------------------

-- Implement GetDataFromDb, SaveDataToDb and UpdateDataToDb native (the db table can be only the default)
Config.DB_integration = true

-- Implement AddItem, GetItem, RemoveItem, AddMoney and RemoveMoney native/trigger
Config.ESX_integration = {
    main_switch = true, -- This is the main switch, if it is disabled all the trigger below will be disabled, otherwise only those you have activated will be functional

    AddItem     = true,
    GetItem     = true,
    RemoveItem  = true,
    AddMoney    = true,
    RemoveMoney = true
}