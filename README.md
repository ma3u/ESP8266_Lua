# NodeMCU

This tutorial will guide you through an example NodeMCU project written in Lua. Your embedded device will continiously send a heartbeat and a reading of a digital input to **relayr Cloud**. Additionally it will be able to receive a command from the cloud which will manipulate one of the digital outputs.

##Firmware

Download a NodeMCU build [here](http://nodemcu-build.com/). Choose the **dev** branch (MQTT module works better) and select the modules that you need (MQTT and CJSON are required for this project to work).

After you receive the custom build, install the [SiLabs serial driver](https://github.com/nodemcu/nodemcu-devkit/wiki/Getting-Started-on-OSX) (if on OSX), and flash the ESP device with help of [ESPtool](https://github.com/themadinventor/esptool). This command might come handy: 

	sudo python esptool.py -p /dev/cu.SLAB_USBtoUART write_flash -fm dio -fs 32m -ff 40m 0x0 your.bin

Of course you'll have to change the paths to point at your files.

After flashing the firmware get something like [ESPlorer](http://esp8266.ru/esplorer/) (you'll need [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)) to ease your interaction with the embedded device. Now you're ready to start programming your ESP device.

##Example project

The example contains four files:

* run.lua
* application.lua
* wifi-setup.lua
* relayr-API.lua

The latter two are modules (packages) to ease your interaction with wifi and *relayr Cloud*. **Run.lua** is the initialization of the application. In you setup your wifi credentials, connect for the wifi and wait that your IP is assigned. **Application.lua** is where you'll do most of your programming. In it you connect to the relayr Cloud, read the sensor data, send data to the cloud and receive commands from it.

The example application reads the data from a [DHT sensor](https://learn.adafruit.com/dht/overview) connected to the *D2* pin of the **NodeMCU** and sends it to the **relyr Cloud**. It also prints name and value of any command sent from the cloud.

If the **M_DEBUG** variable in relayr-API is **true** then the embedded device is going to inform you about what it is doing (connecting to wifi, creating a MQTT client, sending/receiving a message..).