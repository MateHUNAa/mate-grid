fx_version "cerulean"
game "gta5"
lua54 'yes'


author 'MateHUN [mhScripts]'
description 'Template used mCore'
version '1.0.0'


shared_scripts {
    "shared/**.*"
}

server_scripts {
    "server/functions.lua",
    "server/main.lua",
}

client_scripts {
    "client/functions.lua",
    "client/utils.lua",
    "client/draw.lua",
    "client/grid.lua",
    "client/aimController.lua",
    "client/main.lua",
}

server_script "@oxmysql/lib/MySQL.lua"
shared_script '@es_extended/imports.lua'
shared_script '@ox_lib/init.lua'

dependency {
    'mCore',
    'oxmysql',
    'ox_lib'
}


escrow_ignore {
    'shared/config.lua',
    '**/*.editable.lua'
}

files {
    "html/index.html"
}

ui_page "html/index.html"
