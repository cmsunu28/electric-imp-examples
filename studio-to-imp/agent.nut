// This code will set up an HTTP handler for you, 
// so that when a browser (or other request) hits your
// agent URL endpoint with the right query,
// the RGB LED will turn a particular color

// First, let's define a function to handle incoming HTTP requests.

// This function is pretty bulky, because we're including 
// all the ways you could set the LED that are shown in
// the device code example.

// However, as you pick which function works best for you
// on the device side, you can also edit the code here to 
// check only for the LED parameters that you want to use

function requestHandler(request, response) {
    try {
        // Check if the user sent led as a query parameter
        if ("led" in request.query) {
            // If they set LED to 1 or 0, then tell our device that we want
            // the set.led handler to take the info from ledState
            if (request.query.led == "1" || request.query.led == "0") {
                local ledState = (request.query.led == "0") ? false : true; // converts to a boolean
                device.send("set.led", ledState); // sends to the device
            }
            // If they set LED to an RGB list (like "?led=0,0,255")
            // then use the set.colorcode handler to take the raw string from the request
            else if (split(request.query.led,",").len()==3) { // checks for the right format and arguments
                device.send("set.colorcode",request.query.led); // sends to the device
            }
            // If it isn't either of these, assume that someone has
            // sent a letter that is trying to indicate the color.
            else if (["r","g","b","y"].find(request.query.led)>=0) { // checks if it's one of these letters
                device.send("set.color",request.query.led); // sends to the device
            }
        }
        // If your request went through, send a response back to the browser 
        // saying everything was OK.
        response.send(200, "OK");
  } catch (ex) {
        // Otherwise, send an error
        response.send(500, "Internal Server Error: " + ex);
  }
}


// Now that we have our awesome function available, we can
// begin watching for HTTP requests.
http.onrequest(requestHandler);


// For good measure, let's make sure we print out the URLs that we could use
// That will make it easier to copy/paste what we need
server.log("Turn LED On (red):  " + http.agenturl() + "?led=1");
server.log("Turn LED Off: " + http.agenturl() + "?led=0");
server.log("Turn LED green:  " + http.agenturl() + "?led=g");
server.log("Turn blue using RGB color code: " + http.agenturl() + "?led=0,0,255");
