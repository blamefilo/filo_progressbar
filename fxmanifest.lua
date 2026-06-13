fx_version "cerulean"
game "gta5"
lua54 "yes"

name "filo_progressbar"
author "filo studios."
discord "https://discord.gg/bErPEKvRXg"
description ""
version "1.0.0"
ui_page "web/dist/index.html"

client_scripts {
    "client/client.lua"
}

server_scripts {
    "server/sv-version.lua"
}

files {
    "web/dist/**/*"
}