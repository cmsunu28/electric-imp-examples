// Here's a bunch of code with example functions
// that you can pick and choose.

// Each time that the board sends data, it will read all
// the sensors on the board.
// It's not efficient to read all the sensors in order
// to send data on one sensor, but this example will
// give you an idea of how to read the sensors so that
// you can copy/paste/delete what you need.

// We put all the required libraries at the top.
// Temp/Humidity sensor library:
#require "HTS221.device.lib.nut:2.0.2"
// Pressure sensor library:
#require "LPS22HB.device.lib.nut:2.0.0"
// Acceleromter library:
#require "LIS3DH.device.lib.nut:3.0.0"
// RGB LED library:
#require "WS2812.class.nut:3.0.0"

// Connection management
// Connection manager library
#require "ConnectionManager.lib.nut:3.1.1"

// Message manager library
#require "MessageManager.lib.nut:2.4.0"

// Connection manager info
local cm = ConnectionManager({ "blinkupBehavior": CM_BLINK_ALWAYS,
                          "stayConnected"  : true,
                          "startBehavior"  : CM_START_CONNECTED
});

// MessageManager options
local options = {
    "connectionManager": cm
};

local mm = MessageManager(options);


// comment the following in or out depending on whether you'd like
// the LED status lights on the SD card to keep showing after it boots up
// imp.enableblinkup(true);

// Next, set up the sensors.
// The temperature/humidity sensor, pressure sensor, and accelerometer
// all use the I2C bus to send data to our device.
// The following code configures the I2C bus for our sensors:
local i2c = hardware.i2c89;
i2c.configure(CLOCK_SPEED_400_KHZ);

// This sets up the temperature sensor:
local tempSensor = HTS221(i2c);
tempSensor.setMode(HTS221_MODE.ONE_SHOT);

// This sets up the pressure sensor:
local pressureSensor = LPS22HB(i2c);
pressureSensor.softReset();

// This sets up the accelerometer:
local accel = LIS3DH(i2c, 0x32);
accel.reset();
// The accelerometer runs continuously, reading the data
// into a buffer that we can read and clear as necessary.
// Here, we are also going to create a "first in, first out" buffer
accel.configureFifo(true, LIS3DH_FIFO_STREAM_MODE);
// We will also configure interrupt to trigger when there are 30 entries in the buffer
accel.configureFifoInterrupts(true, false, 30);

// We will also set up our RGB LED, which is not a sensor, but
// we can use it to notify us when it has sent data.
// The RGB LED uses the SPI bus and has a pin 
// that gates the power going to it.
// We configure that here:
local spi = hardware.spi257;
spi.configure(MSB_FIRST, 7500);
hardware.pin1.configure(DIGITAL_OUT, 1);
local led = WS2812(spi, 1);

// Here's a function that reads all the sensors,
// sends that data to the agent,
// and blinks the LED once
function readEnvironment(message, reply) {
    
    local var = message.data;
    
    // read the temp/humidity sensor
    local reading = tempSensor.read(); // this will generate two readings in the "reading" object

    // read the pressure sensor
    local pressure = pressureSensor.read(); // this generates one reading in the "pressure" object

    // read the light sensor
    local lightLevel = hardware.lightlevel(); // this generates a value representing the amount of light
    
    // readAccelBuffer();
    local accelVal = accel.getAccel(); // this generates three readings for the x, y, and z axes of the accelorometer, contained in the accelVal object
    accel.setDataRate(100); // This tells us how often to read the accelerometer

    // we'll put all those together in one object that we can send to the agent
    local conditions = { "temperature":  reading.temperature,
                         "humidity": reading.humidity,
                         "pressure": pressure.pressure, 
                         "light": lightLevel,
                         "acceleration": accelVal,
    };
    
    // Send the conditions object to the agent via the message manager
    reply(conditions[var]);

    // Flash the LED so we know it got sent
    led.set(0, [0,128,0]).draw();
    imp.sleep(0.5);
    led.set(0, [0,0,0]).draw();
}

// When the agent sends us "get.var", trigger the readEnvironment function
mm.on("get.var",readEnvironment);

// Check out the agent code for more info!