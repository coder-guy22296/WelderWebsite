



//var http = require('http');

//http.createServer(function (req, res) {
//    res.writeHead(200, {'Content-Type': 'text/plain'});
//    res.end('Hello World\n');
//}).listen(8080, '127.0.0.1');
//console.log('Server running at http://127.0.0.1:8080/');

var express = require('express');
var app = express();

app.get('/', function(req, res){
    res.send('Hello World!\n');
});

app.listen(3000, function () {
    console.log('runing express hello world!');
});
