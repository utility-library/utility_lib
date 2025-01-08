local version = '1.1.0'
local versionurl = "https://raw.githubusercontent.com/utility-library/utility_lib/master/version"

PerformHttpRequest(versionurl, function(error, _version, header)
    _version = _version:gsub("\n", "")

    if version ~= _version then
        print("^1——————————————————————| Attention |—————————————————————")
        print("            ^0New version available [^1".._version.."^0]")
        print("     ^5https://github.com/utility-library/utility_lib")
        print("^1——————————————————————| Attention |—————————————————————^0")
    else
        print([[
^5,ggg,         gg                                               
^5dP""Y8a        88    I8          ,dPYb,         I8              
^5Yb, `88        88    I8          IP'`Yb         I8              
^5 `"  88        88 88888888  gg   I8  8I  gg  88888888           
^5     88        88    I8     ""   I8  8'  ""     I8              
^5     88        88    I8     gg   I8 dP   gg     I8    gg     gg 
^5     88        88    I8     88   I8dP    88     I8    I8     8I 
^5     88        88   ,I8,    88   I8P     88    ,I8,   I8,   ,8I 
^5     Y8b,____,d88, ,d88b, _,88,_,d8b,_ _,88,_ ,d88b, ,d8b, ,d8I 
^5      "Y888888P"Y888P""Y888P""Y88P'"Y888P""Y888P""Y88P""Y88P"888
^5                                                           ,d8I'
     ^0All is updated, have a good day!^5                    ,dP'8I 
^5    ————————————————————————————————————————————        ,8"  8I 
^5                                                        I8   8I 
^5                                                        `8, ,8I 
^5                                                         `Y8P"  ^0]])

        if Config.CleanDBOnServerStart.enabled then
            function print_clean(msg)
                if Config.CleanDBOnServerStart.log then
                    print(msg)
                end
            end

            -- Clean DB
            print_clean("[^2CLEANED^0] table user_inventory...")
            MySQL.Async.execute('DELETE FROM user_inventory WHERE count=@count', {['@count'] = 0})
            Citizen.Wait(200)
            
            print_clean("[^2CLEANED^0] table addon_account_data...")
            MySQL.Async.execute('DELETE FROM addon_account_data WHERE money=@money', {['@money'] = 0})
            Citizen.Wait(200)

            print_clean("[^2CLEANED^0] table trunk_inventory...")
            MySQL.Async.execute('DELETE FROM trunk_inventory WHERE data=@data', {['@data'] = "{}"})
            MySQL.Async.execute('DELETE FROM trunk_inventory WHERE data=@data', {['@data'] = '{"coffre":[]}'})
            Citizen.Wait(200)

            print_clean("[^2CLEANED^0] table datastore_data...")
            MySQL.Async.execute('DELETE FROM datastore_data WHERE data=@data', {['@data'] = "{}"})
            Citizen.Wait(200)

            print_clean("[^2CLEANED^0] table user_accounts...")
            MySQL.Async.execute('DELETE FROM user_accounts WHERE money=@money', {['@money'] = 0})
            Citizen.Wait(200)

            print_clean("[^2CLEANED^0] table phone_calls...\n")
            MySQL.Async.execute('DELETE FROM phone_calls')
        
            if Config.CleanDBOnServerStart.clean_users_table.enabled then
                MySQL.Async.execute('DELETE FROM users WHERE money=@money AND bank=@bank AND job=@job', {
                    ['@money'] = Config.CleanDBOnServerStart.clean_users_table.start_money, 
                    ['@bank'] = Config.CleanDBOnServerStart.clean_users_table.start_bank,
                    ['@job'] = Config.CleanDBOnServerStart.clean_users_table.start_job
                })
                print_clean("[^2CLEANED^0] table users from inactive user...")
            end

            for i=1, #Config.CleanDBOnServerStart.table_to_optimize do
                print_clean("[^2OPTIMIZED^0] table "..Config.CleanDBOnServerStart.table_to_optimize[i].."...")
                MySQL.Async.execute('OPTIMIZE TABLE '..Config.CleanDBOnServerStart.table_to_optimize[i])
                Citizen.Wait(200)
            end

            print("\n[^2OK^0] Daily cleaning finished!^0")    
        end
    end
end)
