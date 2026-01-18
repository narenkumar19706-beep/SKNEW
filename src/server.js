const http = require('http');
const app = require('./app');
const { env } = require('./config/env');
const { createSocketServer } = require('./services/socket.service');

const server = http.createServer(app);
createSocketServer(server);

server.listen(env.port, () => {
  console.log(`RRT backend listening on port ${env.port}`);
});
