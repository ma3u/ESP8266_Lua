
-- application.lua ---

-- Copyright (C) 2016 António P. P. Almeida <appa@perusio.net>

-- Author: António P. P. Almeida <appa@perusio.net>

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- Except as contained in this notice, the name(s) of the above copyright
-- holders shall not be used in advertising or otherwise to promote the sale,
-- use or other dealings in this Software without prior written authorization.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
-- THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

--  Load WiFi and relayr-API modules.
local wifi_setup = require 'wifi-setup'
local relayr = require 'relayr-API'

-- Local definitions.
local format = string.format

--[[
  **************************************************
  **** Configuration of the module starts here. ****
  **************************************************
]]--

--  Your WiFi SSID and password/psk.
local wifi_config = {
  ssid = 'relayrGuest',
  psk = 'ChangingTheWorldwithIoT!'
}
---  MQTT credentials you get from the developer dashboard.
local mqtt_config = {
  user = '03097f9c-95b1-4f24-86bf-2dd700555438',
  -- User password for basic authorization.
  password = 'PkbYdOlz32aP',
  -- This is just a convenience that allows you to identify the
  -- client on the MQTT bro ker. It can be anything you choose.
  clientID = 'TAwl/nJWxTySGvy3XAFVUOA',
  -- MQTT topic for the device that you're connected to.
  topic = '/v1/03097f9c-95b1-4f24-86bf-2dd700555438',
}
--[[
  **************************************************
  **** Configuration of the module ends here.   ****
  **************************************************
]]--

--[[
  **************************************************
  ************ User defined functions. *************
  **************************************************
]]--

--- Number of the GPIO pin used as a digital output.
local output_pin = 0

--- Callback triggered by received data from 'cmd' and 'config'
--  topics. See below for setup function.
-- @param table data
--   Data received via MQTT on both topics.
-- @return nothing
--   Side effects only.
local function received_data(data)
  -- Print the name and value in received JSON message.
  print(format('Received: (name: %s, value: %s).',
               data.name,
               tostring(data.value)))
  -- Process the messages with 'Output' name.
  if data.name == 'Output' then
    if data.value then
      gpio.write(output_pin, gpio.HIGH)
    else
      gpio.write(output_pin, gpio.LOW)
    end
  end
  -- Process the messages with name 'Frequency'.
  if data.name == 'Frequency' then
    -- Update the alarm interval
    -- for sending data to relayr Cloud.
    tmr.interval(2, data.value)
  end
end

--- Wrapper for sending data to the relayr Cloud.
-- @return nothing.
--   Side effects only.
local function send_data()
  -- Read the ADC input.
  local reading = adc.read(0)
  -- Send the data to relayr Cloud.
  relayr.send({ meaning = 'ADC input', value = reading })
end

--- Setup whatever you need in order to send
--  data and connect to the relayr cloud to
--  send it.
-- @return nothing.
--  Side effects only.
local function setup()
  -- Setup GPIO as an output.
  gpio.mode(output_pin, gpio.OUTPUT)
  -- Register the function (callback) in which you
  -- whish to process incoming data (commands).
  relayr.register_data_listener(received_data)
  -- Connect to relayr Cloud.
  relayr.connect(
    -- Pass the MQTT configuration.
    mqtt_config,
    -- Callback when the connection is established.
    -- Trigger the 'send_data' function every 2000 ms.
    function() tmr.alarm(2, 2000, 1, send_data) end
  )
end

-- Setup WiFi and connect to it.
wifi_setup.start(wifi_config)

--- Callback that checks the WiFi link
-- is established and prints the IP address
-- when done.
--
-- @return nothing.
--  Side effects only.
local function wifi_wait_ip()
  if not wifi.sta.getip() then
    print('IP address unassigned: waiting for it.')
  else
    -- IP assigned, unregister the timer and print the IP address.
    tmr.unregister(1)
    print(format('Assigned IP address: %s.', wifi.sta.getip()))
    -- Execute the 'setup' function.
    setup()
  end
end

-- Alarm triggering the wifi_wait_ip function every 2500ms.
tmr.alarm(1, 2500, 1, wifi_wait_ip)
