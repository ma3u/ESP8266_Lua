# NodeMCU

This tutorial will guide you through an example NodeMCU project written in Lua. Your embedded device will continiously send a heartbeat and a reading of a digital input to **relayr Cloud**. Additionally it will be able to receive a command from the cloud which will manipulate one of the digital outputs.

##Firmware

Download the NodeMCU build here. Choose the dev branch (MQTT module works better) and select the modules that you need: cjson, dht, gpio, mqtt, tmr, file and wifi (you can add anything else you would like to play around with).

After you receive the custom build, install the SiLabs serial driver for NodeMCU boards or CH340 driver for WeMos boards. Flash the ESP device with the help of ESPtool. This command might be nifty:

esptool.py -p /dev/yourUSBoutput write_flash -fm dio -fs 32m -ff 40m 0x0 yourpath/your.bin
You'll have to change the paths to point at your port and bin file! To list the names of available ports you can use the following command:

ls /dev/cu*
After flashing the firmware you can use the ESPlorer as a very basic IDE to ease your interaction with the ESP8266 (you'll need JDK). Now you're ready to start programming your ESP device, check out the docs for some basic commands.

##Example project

The example contains four files:

* application.lua
* wifi-setup.lua
* relayr-API.lua

The latter two are modules (packages) to ease your interaction with wifi and *relayr Cloud*. **Run.lua** is the initialization of the application. In you setup your wifi credentials, connect for the wifi and wait that your IP is assigned. **Application.lua** is the only file you should care about. There you set up your WiFi and MQTT credentials, connect to relayr Cloud, read the sensor data, send data to the cloud and receive commands from it.

The example application reads the ADC input of the ESP8266 and controls the output of *D0* pin. It also enables you to change the frequency of sensor readings.

If the **M_DEBUG** variable in relayr-API is **true** then the embedded device is going to inform you about what it is doing (connecting to wifi, creating a MQTT client, sending/receiving a message..).