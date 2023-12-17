fx_version 'cerulean'
game 'gta5'

name 'md-aitaxi'
author 'Mustache_dom'

description 'AI Taxi by mustache dom'

client_scripts {
	'client/**.lua',
}

server_scripts {
    'server/**.lua',
}

shared_scripts {
    'config.lua',
	'@ox_lib/init.lua'
}

lua54 'yes'
dependency '/assetpacks'
