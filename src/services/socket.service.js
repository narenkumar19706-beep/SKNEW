const WebSocket = require('ws');

const subscriptions = new Map();

const addSubscription = (socket, sosId) => {
  if (!subscriptions.has(sosId)) {
    subscriptions.set(sosId, new Set());
  }
  subscriptions.get(sosId).add(socket);
  socket.subscribedSosId = sosId;
};

const removeSubscription = (socket) => {
  const sosId = socket.subscribedSosId;
  if (!sosId) {
    return;
  }

  const set = subscriptions.get(sosId);
  if (set) {
    set.delete(socket);
    if (set.size === 0) {
      subscriptions.delete(sosId);
    }
  }
  socket.subscribedSosId = null;
};

const createSocketServer = (server) => {
  const wss = new WebSocket.Server({ server, path: '/ws' });

  wss.on('connection', (socket) => {
    socket.on('message', (data) => {
      let payload;
      try {
        payload = JSON.parse(data.toString());
      } catch (error) {
        return;
      }

      if (payload?.type === 'subscribe' && payload?.sosId) {
        removeSubscription(socket);
        addSubscription(socket, payload.sosId);
        socket.send(JSON.stringify({ type: 'subscribed', sosId: payload.sosId }));
      }

      if (payload?.type === 'unsubscribe') {
        removeSubscription(socket);
        socket.send(JSON.stringify({ type: 'unsubscribed' }));
      }
    });

    socket.on('close', () => {
      removeSubscription(socket);
    });
  });
};

const broadcastLocation = (sosId, payload) => {
  const sockets = subscriptions.get(sosId);
  if (!sockets) {
    return;
  }

  const message = JSON.stringify({ type: 'location', sosId, payload });
  sockets.forEach((socket) => {
    if (socket.readyState === WebSocket.OPEN) {
      socket.send(message);
    }
  });
};

module.exports = {
  createSocketServer,
  broadcastLocation,
};
