fx_version 'cerulean'

repository 'https://github.com/utility-library/utility_lib'
game 'gta5'

lua54 "yes"

client_scripts {
    "config.lua",
    'client/native.lua',
    'client/functions/*.lua',
    'client/main.lua',
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    
    "config.lua",
    "server/native.lua",
    'server/functions/*.lua',
    "server/main.lua",
    "version_checker.lua"
}

files {
    "client/native_min.lua"
}
