-- Load the required modules.
--   Wifi_setup module hellps you connect to wifi.
local wifi_setup = require 'wifi-setup'
local app = require 'application'

-- Credentials for wifi (SSID and pasword).
local wifi_config = { ssid = 'relayrGuest', psk = 'ChangingTheWorldwithIoT!' }
-- Credential for MQTT connection to the relayr Cloud.
--   usr  - username, psk - password
--   application - main file of your app
--   callback - function which will get triggered when
--   when data is received
local MQTT_config = { usr = '30ffe351-47a6-439d-b1b4-7cf0464a032a',
    psk = '4hFfk6XtyixC',
    application = 'application',
    callback = 'received_data'
}

-- Setup and connect to the wifi.
wifi_setup.start(wifi_config)

-- Wait for an IP to be assigned.
local function wifi_wait_ip()
    if not wifi.sta.getip() then
        print('IP address unassigned: waiting for it.')
    else
        -- IP assigned, unregister the timer and print the IP address.
        tmr.unregister(1)
        print('Assigned IP address: ' .. wifi.sta.getip())
        -- Run the entrance function to your application.
        app.start(MQTT_config)
    end
end
-- Alarm triggering the wifi_wait_ip function every 2500ms.
tmr.alarm(1, 2500, 1, wifi_wait_ip)