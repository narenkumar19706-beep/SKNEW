const { getMessaging } = require('../config/fcm');

const sendDistrictNotification = async ({ district, eventType, payload }) => {
  const messaging = getMessaging();
  if (!messaging) {
    return { delivered: false };
  }

  const topicDistrict = district || 'unknown';
  const message = {
    topic: `district-${topicDistrict}`,
    data: {
      eventType,
      ...payload,
    },
  };

  try {
    const messageId = await messaging.send(message);
    return { delivered: true, messageId };
  } catch (error) {
    return { delivered: false };
  }
};

module.exports = { sendDistrictNotification };
