# NodeMCU

This tutorial will guide you through an example ESP8266 project written in Lua. Your embedded device will read the temperature and humidity through DHT sensor, read a magnetic switch, and send the data to **relayr Cloud**. Additionally it will be able to receive a command from the cloud which will manipulate one of the digital outputs.

##Firmware

Download the NodeMCU build [here](http://nodemcu-build.com/). Choose the **dev** branch (MQTT module works better) and select the modules that you need: cjson, dht, gpio, mqtt, tmr, file and wifi (you can add anything else you would like to play around with).

After you receive the custom build, install the [SiLabs serial driver](https://www.silabs.com/Support%20Documents/Software/Mac_OSX_VCP_Driver.zip) for NodeMCU boards or [CH340 driver](http://www.wemos.cc/downloads/) for WeMos boards. Flash the ESP device with the help of [ESPtool](https://github.com/themadinventor/esptool). This command might be nifty: 

	esptool.py -p /dev/yourUSBoutput write_flash -fm dio -fs 32m -ff 40m 0x0 yourpath/your.bin

You'll have to change the paths to point at your port and bin file! To list the names of available ports you can use the following command:
	
	ls /dev/cu*

After flashing the firmware you can use the [ESPlorer](http://esp8266.ru/esplorer/) as a very basic IDE to ease your interaction with the ESP8266 (you'll need [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)). Now you're ready to start programming your ESP device, check out the [docs](https://nodemcu.readthedocs.io/) for some basic commands.

##Example project

The example contains four files:

* run.lua
* application.lua
* wifi-setup.lua
* relayr-API.lua

The latter two are modules (packages) to ease your interaction with wifi and *relayr Cloud*. **Run.lua** is the initialization of the application. In you setup your wifi credentials, connect for the wifi and wait that your IP is assigned. **Application.lua** is where you'll do most of your programming. In it you connect to the relayr Cloud, read the sensor data, send data to the cloud and receive commands from it.

The example application reads the data from a [DHT sensor](https://learn.adafruit.com/dht/overview) connected to the *D2* pin of the **NodeMCU** and sends it to the **relyr Cloud**. It also prints name and value of any command sent from the cloud.

If the **M_DEBUG** variable in relayr-API is **true** then the embedded device is going to inform you about what it is doing (connecting to wifi, creating a MQTT client, sending/receiving a message..).