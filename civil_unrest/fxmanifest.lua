fx_version 'cerulean'
game 'gta5'

author 'AGI-OS Top Windows Engineer'
description 'Civil Unrest - Standalone AI Driven Native Framework'
version '1.0.0'

ui_page 'ui/index.html'
files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css'
}

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/ai_behavior.lua',
    'client/services.lua',
    'client/epoch_client.lua',
    'client/world_events.lua',
    'client/animations.lua'
}

server_scripts {
    'server/main.lua',
    'server/ai_dialogue.lua',
    'server/services.lua',
    'server/loyalty.lua',
    'server/economy.lua',
    'server/epoch.lua',
    'server/agi_admin.lua'
}
