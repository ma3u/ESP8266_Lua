-- @module relayr-mqtt.lua
-- @author Klemen Lilija lemen@relayr.de>, António, P. P. Almeida <appa@perusio.net>.
-- @date   Jun 9 2016
--
-- @brief Provides a wrapper around the MQTT Node MCU module for the relayr API.
--

-- @table: the module table.
local M  = {
  _VERSION = '0.1',
  _NAME = 'relayr-mqtt',
  _DESCRIPTION = 'relayr API wrapper for the Node MCU MQTT module',
  _DEBUG = false, -- no debugging by default
  _PORT = 1883, -- MQTT borker port
  _CLIENT_ID = 'MQTT relayr API client', -- client ID
  _SERVER = 'mqtt.relayr.io', -- MQTT borker hostname or IP
  _KEEPALIVE = 120, -- keepalive period in seconds
  _QOS = 0, -- Quality of Service
  _RETAIN = 0, -- retain messages to be delivered to new clients or not
  _SECURE = 0, -- secure connection or not (MQTT over TLS or not)
  _AUTORECONNECT = 0, -- to auto reconnect or not
  _COPYRIGHT = [[
                  Copyright (c) 2016 Klemen Lilija lemen@relayr.de>,
                  António P. P. Almeida <appa@perusio.net>

                    Permission is hereby granted, free of charge, to any person
                  obtaining a copy of this software and associated documentation
                  files (the "Software"), to deal in the Software without
                  restriction, including without limitation the rights to use,
                  copy, modify, merge, publish, distribute, sublicense, and/or sell
                  copies of the Software, and to permit persons to whom the
                  Software is furnished to do so, subject to the following
                    conditions:

                    The above copyright notice and this permission notice shall be
                    included in all copies or substantial portions of the Software.
                    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
                    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
                    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
                    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
                    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
                    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
                    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
                    OTHER DEALINGS IN THE SOFTWARE. ]],
}

-- Some local definitions.
local format = string.format
local cjson = cjson
local mqtt = mqtt
local pcall = pcall
local print = print
local conf

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
  setfenv(1, {})
else -- Lua 5.2.
  _ENV = nil
end

-- MQTT client.
local client

--- Subscribes to the 'cmd' and 'config' MQTT topics from the relayr broker.
--
-- @return nothing
--   Side effects only.
local function subscribe_topics()
  -- Subscribe to the 'cmd' and 'config' MQTT topics.
  client:subscribe(
    {
      [format('/v1/%s/cmd/', conf.user)] = 0,
      [format('/v1/%s/config/', conf.user)] = 0
    },
    -- Callback function that is innvoked upon successful subscription.
    function(conn)
      if M._DEBUG then
        print('Succesfully subscribed to "cmd" and "config" topics.')
      end
  end)
end

-- Callback that is invoked when receiving data.
-- MQTT subscription client.
local incoming_data

--- Just copies the given user callback to the incoming data
-- callback (subscriptions)
--
-- @param function callback
--   Function to be used as an incoming data callback.
-- @return nothing
--  Side effects only.
function M.register_data_listener(callback)
  incoming_data = callback
end

--- Registers a callback for received data when the 'connect' event
--  happpens.
-- @return nothing
--   Side effects only.
local function register_receive_callback()
  -- On the 'connect' event for MQTT subscription clients
  -- invoke the given callback.
  client:on('message',
            function(conn, topic, data)
              if data then
                -- Print the received data.
                if M._DEBUG then
                  print(format('Data received: %s', data))
                end
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

--- Sends data to relayr cloud. It publishes
--
-- @param data
--   Lua table including 'meaning' and 'value'.
-- @return nothing
--   Side effects only.
function M.send(data)
  -- Encode the data into JSON message and publish it.
  local ok, json = pcall(cjson.encode, data)
  -- If the JSON encoding succeeded then publish the data.
  if ok then
    client:publish(
      format('/v1/%s/data/', conf.user),
      json,
      conf.qos or M._QOS,
      conf.retain or M._RETAIN,
      function(client)
        if M._DEBUG then
          print(format('Sent: %s', json))
        end
    end)
  else
    if M._DEBUG then
      print('Failed to encode JSON.')
    end
  end
end

--- Establishes a connection to the relayr cloud MQTT broker.
--
-- @param table config
--   MQTT configuration table with: Username, Password, etc.
-- @param function callback
--   Callback invoked when the client connects.
-- @return nothing
--   Side effects only.
function M.connect(config, callback)
  -- Save the config table locally.
  conf = config
  -- Instantiate the MQTT client.
  client = mqtt.Client(conf.client_id or M._CLIENTID,
                       conf.keepalive or M._KEEPALIVE,
                       conf.user, conf.password)
  -- Check if client was created.
  if not client then print('not initialized') return end
  -- Register callback for received data from subscribed topic.
  register_receive_callback()
  -- Connect to the relayr MQTT broker.
  client:connect(
    conf.server or M._SERVER,
    conf.port or M._PORT,
    config.secure or M._SECURE,
    config.autoreconnect or M._AUTORECONNECT,
    function(con)
      print('Connection to the broker established.')
      -- Subscribe to the '/cmd' topic.
      subscribe_topics()
      -- Trigger a callback when connection is established.
      callback()
    end,
    -- Callback that is invoked if there's a problem establishing a
    -- connection with the MQTT broker.
    function(con, reason)
      -- If the connection could not be established print the reason for it.
      print(format('Connection to the broker could not be established. Reason: %s', reason))
  end)
end

-- Return the module table.
return M
