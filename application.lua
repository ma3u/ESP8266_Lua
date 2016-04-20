---  Load WiFi and relayr-API modules.
local wifi_setup = require 'wifi-setup'
local relayr = require 'relayr-API'

---  Your WiFi SSID and password.
local WIFI_config = { ssid = 'relayr24', psk = 'wearsimaspants' }
---  MQTT credentials from the developer dashboard.
local MQTT_config = {
    deviceID = '03097f9c-95b1-4f24-86bf-2dd700555438',
    user = '03097f9c-95b1-4f24-86bf-2dd700555438',
    password = 'PkbYdOlz32aP',
    clientID = 'TAwl/nJWxTySGvy3XAFVUOA',
    topic = '/v1/03097f9c-95b1-4f24-86bf-2dd700555438/',
    server = 'mqtt.relayr.io'
}

--- Number of the GPIO pin used as a digital output.
local outputPin = 0

--- Callback triggered by received data from 'cmd' and 'config' topics.
local function received_data(data)
    -- Print the name and value in received JSON message.
    print(string.format('Received: (name: %s, value: %s)', data.name, tostring(data.value)))
    -- Process the messages with 'Output' name.
    if data.name == 'Output' then
        if data.value then
            gpio.write(outputPin, gpio.HIGH)
        else
            gpio.write(outputPin, gpio.LOW)
        end
    end
    -- Process the messages with name 'Frequency'.
    if data.name == 'Frequency' then
        -- Update the alarm interval
        -- for sending data to relayr Cloud.
        tmr.interval(2, data.value)
    end
end

--- Function for sending data to relayr Cloud.
local function send_data()
    -- Read the ADC input.
    local reading = adc.read(0)
    -- Send the data to relayr Cloud.
    relayr.send({ meaning = 'ADC', value = reading })
end

--- Connect to ralyr Cloud and setup GPIOs.
local function setup()
    -- Setup GPIO as an output.
    gpio.mode(outputPin, gpio.OUTPUT)
    -- Register the function (callback) in which you
    -- whish to process incoming data (commands).
    relayr.register_data_listener(received_data)
    -- Connect to relayr Cloud.
    relayr.connect(MQTT_config,
        -- Callback when the connection is established.
        function()
            -- Trigger 'send_data' function every 2000ms
            tmr.alarm(2,2000,1,send_data)
        end)
end

--- Setup WiFi and connect to it.
wifi_setup.start(WIFI_config)
-- Check if the IP is already assigned.
local function wifi_wait_ip()
    if not wifi.sta.getip() then
        print('IP address unassigned: waiting for it.')
    else
        -- IP assigned, unregister the timer and print the IP address.
        tmr.unregister(1)
        print('Assigned IP address: ' .. wifi.sta.getip())
        -- Execute the 'setup' function.
        setup()
    end
end
-- Alarm triggering the wifi_wait_ip function every 2500ms.
tmr.alarm(1, 2500, 1, wifi_wait_ip)