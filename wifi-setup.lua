local M = { _VERSION = '0.1',
    _NAME = 'WiFi setup',
    _DESCRIPTION = 'Setup a WiFi connection',
    _CONFIG = nil
}

-- Define needed functions in the local scope
local wifi = wifi
local print = print
local pairs = pairs

-- Avoid polluting the global environment.
-- If we are in Lua 5.1 this function exists.
if _G.setfenv then
    setfenv(1, {})
else -- Lua 5.2.
    _ENV = nil
end

--- Callback that iterates through available access points,
-- and connects to user defined one.
--
-- @param t table
--   Array of SSID, authmode, RSSI, BSSID and channel.
-- @return nothing
--   Side effects only.
local function wifi_setup(t)
    -- Check if table with APs is not nil.
    if t then
        -- Iterate through access points.
        for key, value in pairs(t) do
            -- Connect, if the AP is in th user's config file
            if M._CONFIG.ssid == key then
                wifi.setmode(wifi.STATION);
                wifi.sta.config(key, M._CONFIG.psk)
                wifi.sta.connect()
                print('Connecting to ' .. key .. '...')
            end
        end
    else
        print('Could not get the access point list.')
    end
end

--- Sets up an WiFi connection for a given (SSID, PSK) pair.
-- @param config
--   WiFi configuration for a given SSID, PSK, etc.
-- @return nothing
--   Side effects only.
function M.start(config)
    wifi.setmode(wifi.NULLMODE)
    wifi.setmode(wifi.STATION)
    --save config table
    M._CONFIG = config
    --get access points
    wifi.sta.getap(wifi_setup)
end

return M