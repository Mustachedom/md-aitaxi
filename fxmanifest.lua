name "mustache-aitaxi"
author "mustache_dom"
description "AI Taxi by mustache dom"
fx_version "cerulean"
game "gta5"

client_scripts {
	'client/**.lua',
	
}

server_scripts {
    'server/**.lua',
	
}

shared_scripts {
    'config.lua',
	 '@ox_lib/init.lua',
	
	
}


lua54 'yes'

dependency '/assetpacks'
