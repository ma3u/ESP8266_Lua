--  Load the wifi setup module.
local wifi_setup = require 'wifi_setup'

--  @table: WiFi network SSID and password/psk.
local wifi_config = {
  -- Replace with the desired network SSID.
  ssid = 'relayrGuest',
  -- Replace with the desired network SSID.
  psk = 'ChangingTheWorldwithIoT!'
}

-- Some local definitions.
local format = string.format
local alarm = tmr.alarm

-- Setup WiFi and connect to it.
wifi_setup.start(wifi_config)

--- Callback that checks the WiFi link
-- is established and prints the IP address
-- when done.
--
-- @return nothing.
--  Side effects only.
function wifi_wait_ip()
  if not wifi.sta.getip() then
    print('IP address unassigned: waiting for it.')
  else
    -- IP assigned, unregister the timer and print the IP address.
    tmr.unregister(wifi_setup_timer)
    print(format('Assigned IP address: %s.', wifi.sta.getip()))
    -- Execute the 'setup' function.
    setup()
  end
end

-- Run the event loop for establishing a WiFi connection.
alarm(app_config and app_config.wifi_setup_timer or wifi_setup._CONFIG._TIMER,
      wifi_config.period or wifi_setup._CONFIG._PERIOD,
      tmr.ALARM_AUTO,
      wifi_setup.wait_ip)
