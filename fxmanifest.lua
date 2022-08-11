fx_version 'cerulean'

game 'gta5'

client_scripts {
    "@utility_framework/client/api.lua",
    "config.lua",
    'client/native.lua',
    'client/main.lua',
}

server_scripts {
    "@utility_framework/server/api.lua",
    "config.lua",
    "@mysql-async/lib/MySQL.lua",
    "server/native.lua",
    "server/main.lua",
    "version_checker.lua"
}

files {
    "client/native_min.lua"
}
