local M = {}

-- Load the relayr-API module.
local relayr = require 'relayr-API'
-- Pin number for the GPIO outpu.
local outputPin = 4
-- DHT input
local dhtInput = 5
-- Magnetic switch input
local magneticInput = 2

-- Receive data from '/cmd' (commands) MQTT topic
function M.received_data(data)
    print(string.format('Received: (name: %s, value: %s)', data.name, tostring(data.value)))
    if data.value then
        gpio.write(outputPin, gpio.LOW)
    else
        gpio.write(outputPin, gpio.HIGH)
    end
end

-- Send data to the relayr Cloud.
local function send_data()
    -- Read DHT data.
    local status, temp, humi = dht.read(dhtInput)
    -- Read the magnetic switch input.
    local magneticValue = gpio.read(magneticInput)
    -- If the reading staus is 'ok' print it.
    if status == dht.OK then
        -- Send the dht data to the relayr Cloud
        relayr.send({{ meaning = 'Temperature', value = temp },
            { meaning = 'Humidity', value = humi },
            { meaning = 'Switch', value = magneticValue}})
    end
end

-- Entrance point of your application.
function M.start(config)
    -- Set up a GPIO port as an output.
    gpio.mode(outputPin, gpio.OUTPUT)
    gpio.mode(magneticInput, gpio.INPUT)
    -- Connect to relayr Cloud.
    relayr.connect(config,
        -- Callback when the connection is established.
        function()
            -- Trigger send_data function every 2000ms
            tmr.alarm(1,2000,1,send_data)
        end)
end

return M