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
function readEnvironment() {

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
                         "response":null
    };

    agent.send("reading.sent", conditions);

    // Flash the LED so we know it got sent
    led.set(0, [0,128,0]).draw();
    imp.sleep(0.5);
    led.set(0, [0,0,0]).draw();
}

// But what will cause us to send this info?
// We have a few options. One is to send the info on
// a timed interval. For that, uncomment the code below:
/*
const SLEEP_TIME = 15; // Send it every 15 seconds
readEnvironment(); // change this to whatever you'd like to send at an interval
// Then go to sleep for SLEEP_TIME seconds
imp.onidle(function() {
    server.sleepfor(SLEEP_TIME);
});
*/

// We could also send the data based on the level of light, using the light sensor
// Uncomment the lines below to do that

/*
const LIGHT_THRESHOLD=3000; // You can adjust this level to whatever works for you
const READING_DELAY=30; // wait 30 seconds before checking the sensor again
if (hardware.lightlevel()>LIGHT_THRESHOLD) {
    readEnvironment();
    imp.sleep(READING_DELAY);
}
*/

// We can also send data when the accelerometer detects that we've flipped the board upside-down
// This is a rotation around the Z axis of the board.
// We're being a bit sloppy about it here, and this method
// will waste your battery, but it's useful for proof of concept.
// There's better examples of how to do it in the GitHub repo: https://github.com/electricimp/LIS3DH/tree/master/examples
/*
const READING_DELAY=30; // wait 30 seconds before checking the sensor again
accel.setDataRate(100); // This tells us how often to read the accelerometer
local accelNow=accel.getAccel();
if (accelNow.z<0) {
    readEnvironment();
    imp.sleep(READING_DELAY);
}
server.log(accelNow.x);
server.log(accelNow.y);
server.log(accelNow.z);
imp.onidle(function() {
    server.sleepfor(5); // this means that it will wait 5 seconds between each reading
});
*/
const INTERVAL = 5;
function loop() {

    // Our simplest option is to uncomment the
    // line below to read the sensors every INTERVAL seconds
    readEnvironment();

    // We could also try reading the sensors whenever the imp has light on it.
    // In that case, we'll use the line below instead
    // checkLightLevels();
    
    // We can also send data when the accelerometer detects that we've flipped the board upside-down
    // This is a rotation around the Z axis of the board.
    // We're being a bit sloppy about it here, and this method
    // will waste your battery, but it's useful for proof of concept.
    // checkIfUpsideDown();
    
    // We could also trigger the environment data if it's too hot:
    // checkIfHot(30.0); // checks if it is hotter than 30C
    
    // Or too humid:
    // checkIfHumid(50.0) // checks if the humidity is higher than 50

    // Or if the atmospheric pressure is within a particular range
    // checkPressure(998.0) // checks if the pressure is over 998.0
    
    // There's better examples of how to do accelerometer interrupts in the GitHub repo: https://github.com/electricimp/LIS3DH/tree/master/examples

    // We'll need this line regardless of what we do        
    imp.wakeup(INTERVAL, loop.bindenv(this)); // wakes the imp up every INTERVAL seconds
}

// All the functions we referenced above are below.
// It's really silly to have all of these written out in this way
// but we wanted it to be easy for you to copy/paste/delete!
// Feel free to take what you need and delete the rest.
// Just don't delete the last line, which calls our loop!

// Here's the function for checking light levels
function checkLightLevels() {
    const READING_DELAY=30; // wait 30 seconds before checking the sensor again
    const LIGHT_THRESHOLD=3000; // You can adjust this level to whatever works for you
    if (hardware.lightlevel()>LIGHT_THRESHOLD) {
        readEnvironment();
        imp.sleep(READING_DELAY);
    }
}

// And the one for checking if the device is upside-down
function checkIfUpsideDown() {
    const READING_DELAY=30; // wait 30 seconds before checking the sensor again
    accel.setDataRate(100); // This tells us how often to read the accelerometer
    local accelNow=accel.getAccel();
    if (accelNow.z<0) {
        readEnvironment();
        imp.sleep(READING_DELAY);
    }
    server.log(accelNow.x);
    server.log(accelNow.y);
    server.log(accelNow.z);
}

function checkIfHot(threshold) {
    const READING_DELAY=30; // wait 30 seconds before checking the sensor again
    local tempNow=tempSensor.read().temperature;
    server.log(tempNow);
    if (tempNow>threshold) {
        readEnvironment();
        imp.sleep(READING_DELAY);
    }
}

function checkIfHumid(threshold) {
    const READING_DELAY=30; // wait 30 seconds before checking the sensor again
    local humidNow=tempSensor.read().humidity;
    server.log(humidNow);
    if (humidNow>threshold) {
        readEnvironment();
        imp.sleep(READING_DELAY);
    }
}

function checkPressure(threshold) {
    const READING_DELAY=30; // wait 30 seconds before checking the sensor again
    local pressureNow=pressureSensor.read().pressure;
    server.log(pressureNow);
    if (pressureNow>threshold) {
        readEnvironment();
        imp.sleep(READING_DELAY);
    }
}


// Finally, don't forget to run the loop
loop();

// Check out the agent code for more info!

