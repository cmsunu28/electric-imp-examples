// This code will take info from your device and send it over
// to a Twilio Studio Flow when a certain thing happens on your
// device (see your device code to pick one)

// We will contaact our Studio Flow using a POST request.
// We'll do that with the following function:
function triggerFlow(data, callback=null) {
    local text = format("{\"response\": \"Temperature: %.2f, Humidity: %.2f, Pressure: %.2f, Light:%.2f, Acceleration: (%.2f,%.2f,%.2f)\"}", 
    data.temperature, data.humidity, data.pressure, data.light, data.acceleration.x, data.acceleration.y, data.acceleration.z);

    server.log(text);

    local url = __VARS.TWILIO_STUDIO_URL;
    local auth = http.base64encode(__VARS.TWILIO_ACCOUNT_SID + ":" + __VARS.TWILIO_AUTH_TOKEN);
    local headers = { "Authorization": "Basic " + auth };
    local body = http.urlencode({
        From = "MyElectricImp",
        To = "TwilioStudioFlow",
        Parameters = text
    });
    local request = http.post(url, headers, body);
    if (callback == null) return request.sendsync();
    else request.sendasync(callback);
}

// Make sure we connect reading.sent (from the device) to
// our triggerFlow function!
device.on("reading.sent", triggerFlow);
