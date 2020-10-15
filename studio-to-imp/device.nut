// Import Electric Imp’s WS2812 library
//    (The WS2812 is the type of RGB LED that is on the board.)
#require "WS2812.class.nut:3.0.0"

// Let's set up some global variables we can use later
spi <- null;
led <- null;

// SPI stands for "Serial Peripheral Interface."
// It is how we will send info to the RGB LED.
// We'll configure it here to use a particular communication method over pin1.
spi = hardware.spi257;
spi.configure(MSB_FIRST, 7500);
hardware.pin1.configure(DIGITAL_OUT, 1);

// When we reference the LED variable, we'll be talking to the WS2812 LED 
//    (via the library we called in earlier)
// over pin 1, as defined above.
led = WS2812(spi, 1);

// Here's some functions you can use to set off the LED.
// In practice, you'll only really need one of these,
// but we're providing you with a few ways
// to address the LED here in case you need variety.

// This function sets the LED by state. 0 is off, 1 is on and red.
function setLedState(state) {
    local color = state ? [255,0,0] : [0,0,0];
    led.set(0, color).draw();
}

// This function sets the LED by a given color.
// r is red, b is blue, g is green, and y is yellow.
function setLedColor(color) {
    if (color=="r") {
        led.set(0,[255,0,0]);
    }
    else if (color=="b") {
        led.set(0,[0,0,255]);
    }
    else if (color=="g") {
        led.set(0,[0,255,0]);
    }
    else if (color=="y") {
        led.set(0,[255,255,0]);
    }
    led.draw();
}

// This function sets the color by RGB code.
// Each value is out of 255.
// The input is a string of the three values, separated by a comma.
function setLedColorByCode(code) {
    local rgb=split(code,",");
    led.set(0,[rgb[0].tointeger(),rgb[1].tointeger(),rgb[2].tointeger()]);
    led.draw();
}

// You can reach each of the above functions by sending info from the agent to the device.
// The code below sets up how we handle this incoming info from the agent.
agent.on("set.led", setLedState);
agent.on("set.color",setLedColor);
agent.on("set.colorcode",setLedColorByCode);

// check out the agent code to understand how this works!
