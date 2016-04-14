local M  = {_VERSION = '0.1',
    _NAME = 'relayrAPI',
    _DESCRIPTION = 'relayr wrapper for the NodeMCU MQTT module',
    _DEBUG = true,
    _SERVER = 'mqtt.relayr.io',
    _PORT = 1883,
}

--- Some local definitions.
local client
local conf
local app
local print = print
local mqtt = mqtt
local cjson = cjson
local pcall = pcall
local type = type
local format = string.format
local require = require

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
    setfenv(1, {})
else -- Lua 5.2.
    _ENV = nil
end

--- Subscribe to a MQTT topic.
--
-- @return nothing
--   Side effects only.
local function subscribe_topic()
    client:subscribe(format('/v1/%s/cmd/', conf.usr), 0, function(conn)
        if M._DEBUG then print('Succesfully subscribed to "cmd" topic') end
    end)
end

--- Register a callback for received data.
--
-- @return nothing
--   Side effects only.
local function register_receive_callback()
    client:on("message",
        function(conn, topic, data)
            if data then
                if M._DEBUG then print('Data recived: ' .. data) end
                -- Decode the JSON data and pass it to the app.
                local d = cjson.decode(data)
                -- Check if 'received_data(d)' function exists,
                -- if so call it and add 'data' as an argument.
                if not type(app[conf.callback]) then
                    print('"received_data(data)" function does not exist in the app')
                else
                    app[conf.callback](d)
                end
            end
        end)
end

--- Send a message to relyr cloud
-- @param data
--   Data in a form of lua table.
-- @return nothing
--   Side effects only.
function M.send(data)
    -- Encode the data into JSON message and publish it.
    local ok, json = pcall(cjson.encode, data)
    if ok then
        client:publish(format('/v1/%s/data/', conf.usr), json, 0, 0,
            function(client)
                if M._DEBUG then print('Sent: ' .. json) end
            end)
    else
        if M._DEBUG then print('Failed to encode!') end
    end
end

--- Connect the client to the relayr cloud.
--
-- @param config
--   MQTT configuration table with: Username, Password, etc.
-- @param callback
--   Callback to be invoked when client is connects.
-- @return nothing
--   Side effects only.
function M.connect(config, callback_connected)
    -- Save the config table locally.
    conf = config
    -- Load the module where the main application is
    -- going to run (defined in the config table).
    app = require(conf.application)
    -- Create the MQTT client.
    client = mqtt.Client('Takvk21tZSXO/sIWB6ok1vw', 120, config.usr, config.psk)
    -- Check if client was created.
    if not client then print('not initialized') return end
    -- Register callback for received data from subscribed topic.
    register_receive_callback()
    -- Connect to the relayr MQTT broker.
    client:connect(M._SERVER, M._PORT, 0, 1, function(con)
        print('Connection to the broker established.')
        -- Subscribe to the '/cmd' topic.
        subscribe_topic()
        -- Trigger a callback when connection is established.
        callback_connected()
    end, function(con, reason)
        -- If the connection could not be established print the reason for it.
        print(format('Connection to the broker could not be established. Reason: %s', reason))
    end)
end

return M