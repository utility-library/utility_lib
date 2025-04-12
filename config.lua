Config = {}

Config.UpdateCooldown = 500 -- (default: 500ms) This is the time when every loop will update (dialogues, markers, utilityNet rendering)

-- Used for utility net dynamic update based on workload/number of entities, this is the timeout of a single loop in performance-saving mode
Config.UtilityNetDynamicUpdate = 3000

Config.EmitterTriggerForSyncedVariable = true -- (default: false) Active the emitter for synced variables, can be a problem in the side of security since it could be abused by modders to pretend to be in a marker!

Config.CleanDBOnServerStart = { --[BETA] (We recommend that you make a backup of your database before testing this feature!)
    enabled = false,
    log = true,
    table_to_optimize = {
        "datastore_data",
        "addon_account_data",
        "owned_vehicles",
        "phone_messages",
        "phone_calls",
        "users",
        "user_documents",
        "user_inventory",
        "trunk_inventory",
    },
    clean_table = { -- SEE THE CODE BEFORE USE THIS
        user_inventory      = true,
        addon_account_data  = true,
        trunk_inventory     = true,
        datastore_data      = true,
        user_accounts       = true,
        phone_calls         = true
    },
    clean_users_table = { -- Remove from the users table the person that have the money and the bank equal to the start (simply delete the people that join and 5 second later leave, help removing from the users table the people that will never enter your server again)
        enabled = false,
        start_money = 1000,
        start_bank = 20000,
        start_job = "unemployed"
    }
}
