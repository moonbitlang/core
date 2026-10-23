const socket = new WebSocket(process.argv[2]);
socket.addEventListener("open", (event) => {
    console.log("Connection opened");
    socket.send("Hello, Server!");
});
socket.addEventListener("message", (event) => {
    console.log("Message from server: ", event.data);
    socket.close();
});
socket.addEventListener("close", (event) => {
    console.log("Connection closed");
});
socket.addEventListener("error", (event) => {
    console.log("WebSocket error: ", event);
});
