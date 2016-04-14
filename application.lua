local M = {}

-- Load the relayr-API module.
local relayr = require 'relayr-API'
-- Pin number for the GPIO outpu.
local pin = 3

-- Receive data from '/cmd' (commands) MQTT topic
function M.received_data(data)
    print(string.format('Received: (name: %s, value: %s)', data.name, tostring(data.value)))
    if data.value then
        gpio.write(pin, gpio.HIGH)
    else
        gpio.write(pin, gpio.LOW)
    end
end

-- Send data to the relayr Cloud.
local function send_data()
    -- Read DHT data at pin 2.
    local status, temp, humi = dht.read(2)
    -- If the reading staus is 'ok' print it.
    if status == dht.OK then
        -- Send the dht data to the relayr Cloud
        relayr.send({{ meaning = 'Temperature', value = temp },
            { meaning = 'Humidity', value = humi }})
    end
end

-- Entrance point of your application.
function M.start(config)
    -- Set up a GPIO port as an output.
    gpio.mode(pin, gpio.OUTPUT)
    -- Connect to relayr Cloud.
    relayr.connect(config,
        -- Callback when the connection is established.
        function()
            -- Trigger send_data function every 2000ms
            tmr.alarm(1,2000,1,send_data)
        end)
end

return M