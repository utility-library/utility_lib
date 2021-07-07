fx_version 'cerulean'

game 'gta5'

client_scripts {
    "config.lua",
    'client/native.lua',
    'client/main.lua',
}

server_scripts {
    "config.lua",
    "@mysql-async/lib/MySQL.lua",
    "server/native.lua",
    "server/main.lua",
}
