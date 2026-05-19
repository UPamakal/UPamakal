const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendChatNotification = onDocumentCreated(
  'chat_rooms/{chatRoomId}/messages/{messageId}',
  async (event) => {
    const message = event.data && event.data.data();
    if (!message) return;

    const { chatRoomId } = event.params;
    const { receiverId, senderId, text } = message;
    if (!receiverId || !senderId || !text) return;

    const db = admin.firestore();
    const [receiverSnap, senderSnap, roomSnap] = await Promise.all([
      db.collection('users').doc(receiverId).get(),
      db.collection('users').doc(senderId).get(),
      db.collection('chat_rooms').doc(chatRoomId).get(),
    ]);

    const receiver = receiverSnap.data();
    const token = receiver && receiver.fcmToken;
    if (!token) {
      logger.info('Receiver has no FCM token', { receiverId, chatRoomId });
      return;
    }

    const sender = senderSnap.data() || {};
    const room = roomSnap.data() || {};
    const senderName = sender.displayName || sender.email || 'New message';
    const listingTitle = room.listingTitle || 'UPamakal chat';

    await admin.messaging().send({
      token,
      notification: {
        title: senderName,
        body: `${listingTitle}: ${text}`,
      },
      data: {
        type: 'chat_message',
        chatRoomId,
        senderId,
        listingId: room.listingId || '',
      },
      android: {
        notification: {
          channelId: 'chat_messages',
        },
      },
    });
  },
);
