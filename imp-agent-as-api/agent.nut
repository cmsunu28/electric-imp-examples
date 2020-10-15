// We will use a library called Rocky 
// that makes it easier to make APIs
#require "rocky.agent.lib.nut:3.0.0"

// We'll also use the Message Manager library
// which lets us do asynchronous stuff with the device
#require "MessageManager.lib.nut:2.4.0"

// define some variables so we can use message manager
local mm = MessageManager();

// define the variables we will need to make our API
local api = Rocky.init({ "timeout": 5 });

// Let's say that when we hit an endpoint that has 
// ?var=variablename as the query, that we will
api.get("/", function(context) {
    try {
        // Log the user
        server.log("got "+context.req.query.var);
        
        // Ask device to get this variable; pass in our Rocky context for this request to the mm.send,
        // as this then means the reply callback will have it ready to send a reply (it'll be in
        // message.metadata).
        mm.send("get.var", context.req.query.var, null, null, context).onReply(function (message, response) {
            // response is whatever "reply()" has been called with
            // message.metadata is the metadata passed into mm.send() - in this case, it's our rocky context
            message.metadata.send(200, {"data":response, "name":message.payload.data}); 
        });
        
    } catch(e) {
        server.log("Error processing request: "+e);
        context.send(404, "Error");
        
    }
}).onTimeout(function(context) {
    context.send(200, { "text": "No response"});
});
