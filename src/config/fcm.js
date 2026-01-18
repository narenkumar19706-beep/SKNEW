const admin = require('firebase-admin');
const { env } = require('./env');

let messagingClient = null;

const initializeFcm = () => {
  if (messagingClient) {
    return messagingClient;
  }

  if (!env.fcmProjectId) {
    return null;
  }

  const serviceAccountJson = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    const credentials = JSON.parse(serviceAccountJson);
    admin.initializeApp({
      credential: admin.credential.cert(credentials),
      projectId: env.fcmProjectId,
    });
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp({ projectId: env.fcmProjectId });
  } else {
    return null;
  }

  messagingClient = admin.messaging();
  return messagingClient;
};

const getMessaging = () => initializeFcm();

module.exports = { getMessaging };
