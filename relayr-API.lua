local M  = {_VERSION = '0.1',
    _NAME = 'relayrAPI',
    _DESCRIPTION = 'relayr wrapper for the NodeMCU MQTT module',
    _DEBUG = true,
    _PORT = 1883,
}

--- Some local definitions.
local client
local conf
local incoming_data
local print = print
local mqtt = mqtt
local cjson = cjson
local pcall = pcall
local format = string.format


-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
    setfenv(1, {})
else -- Lua 5.2.
    _ENV = nil
end

--- Subscribe to 'cmd' and 'config' MQTT topics.
--
-- @return nothing
--   Side effects only.
local function subscribe_topics()
    -- Subscribe to 'cmd' and 'config'.
    client:subscribe({ [format('%scmd/', conf.topic)] = 0,
        [format('%sconfig/', conf.topic)] = 0 },
        function(conn)
            -- Callback message on successful subscription.
            if M._DEBUG then print('Succesfully subscribed to "cmd" and "config" topic') end
        end)
end

function M.register_data_listener(callbalck)
    incoming_data = callbalck
end

--- Register a callback for received data.
--
-- @return nothing
--   Side effects only.
local function register_receive_callback()
    client:on("message",
        function(conn, topic, data)
            if data then
                -- Print the received data.
                if M._DEBUG then print('Data recived: ' .. data) end
                -- Decode the JSON data.
                local d = cjson.decode(data)
                -- Check if callback function is registered
                -- in the main application.
                if incoming_data then
                    incoming_data(d)
                else
                    if M._DEBUG then print('Listener is not registered.') end
                end
            end
        end)
end

--- Send data to relyr cloud.
--
-- @param data
--   Lua table including 'meaning' and 'value'.
-- @return nothing
--   Side effects only.
function M.send(data)
    -- Encode the data into JSON message and publish it.
    local ok, json = pcall(cjson.encode, data)
    if ok then
        client:publish(format('%sdata/', conf.topic), json, 0, 0,
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
--   Callback invoked when the client connects.
-- @return nothing
--   Side effects only.
function M.connect(config, callback)
    -- Save the config table locally.
    conf = config
    -- Load the
    -- Create the MQTT client.
    client = mqtt.Client(conf.clientID, 120, conf.user, conf.password)
    -- Check if client was created.
    if not client then print('not initialized') return end
    -- Register callback for received data from subscribed topic.
    register_receive_callback()
    -- Connect to the relayr MQTT broker.
    client:connect(conf.server, M._PORT, 0, 1, function(con)
        print('Connection to the broker established.')
        -- Subscribe to the '/cmd' topic.
        subscribe_topics()
        -- Trigger a callback when connection is established.
        callback()
    end, function(con, reason)
        -- If the connection could not be established print the reason for it.
        print(format('Connection to the broker could not be established. Reason: %s', reason))
    end)
end

return M