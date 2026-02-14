const functions = require("firebase-functions/v2");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const axios = require("axios");

if (admin.apps.length === 0) {
  admin.initializeApp();
}


exports.sendMessageNotification = functions.firestore.
    onDocumentCreated("topic_chats/{chatId}/messages/{messageId}",
        async (event, context) => {
          const message = event.data.data();
          const {chatId, messageId} = event.params;

          try {
            // 1. Get chat document data
            const chatDoc = await admin.firestore()
                .collection("topic_chats")
                .doc(chatId)
                .get();

            if (!chatDoc.exists) {
              console.log(`❌ Chat ${chatId} not found`);
              return;
            }

            // 2. Extract participants and verify
            const participants = chatDoc.data().participants;
            if (!Array.isArray(participants) || participants.length !== 2) {
              console.log(`⚠️ Invalid participants in chat ${chatId}`);
              return;
            }

            // 3. Identify receiver
            const senderId = message.senderId;
            const receiverId = participants.find((id) => id !== senderId);

            if (!receiverId) {
              console.log(`🔍 Can't find receiver in chat ${chatId}`);
              return;
            }

            // 4. Get sender's name (for notification title)
            const senderDoc = await admin.firestore()
                .collection("users")
                .doc(senderId)
                .get();

            const senderName = senderDoc.exists ?
        senderDoc.data().name || "Someone" :
        "Someone";

            // 5. Get receiver's FCM token
            const receiverDoc = await admin.firestore()
                .collection("users")
                .doc(receiverId)
                .get();

            if (!receiverDoc.exists) {
              console.log(`📭 Receiver ${receiverId} not found`);
              return;
            }

            const fcmToken = receiverDoc.data().fcmToken;
            if (!fcmToken) {
              console.log(`🔕 No FCM token for ${receiverId}`);
              return;
            }

            // 6. Prepare and send notification
            const payload = {
              token: fcmToken,
              notification: {
                title: `${senderName}: ${chatDoc.data().topic}`,
                body: message.text,
                //          sound: "default"
              },
              data: {
                type: "chat",
                chatId: chatId,
                senderId: senderId,
                messageId: messageId,
              },
              apns: {
                payload: {
                  aps: {
                    mutableContent: 1,
                    sound: "default",
                    category: "MESSAGE_CATEGORY",
                  },
                },
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "MESSAGES_CHANNEL",
                  sound: "default",
                  icon: "ic_notification",
                },
              },
            };

            await admin.messaging().send(payload);
            console.log(`📨 Notification sent to ${receiverId}`);
          } catch (error) {
            console.error("🔥 Critical error:", error);
          }
        });


exports.sendGroupNotification = functions.firestore.onDocumentCreated("group_chats/{chatId}/messages/{messageId}", async (event, context) => {
  const message = event.data.data();
  const {chatId, messageId} = event.params;

  try {
    // 1. Get chat document data
    const chatDoc = await admin.firestore()
        .collection("group_chats")
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      console.log(`❌ Chat ${chatId} not found`);
      return;
    }

    const participants = chatDoc.data().participants;
    const senderId = message.senderId;

    // 2. For group chats, find participants other than sender
    const receiverIds = participants.filter((id) => id !== senderId);

    if (receiverIds.length === 0) {
      console.log(`🔍 No receivers found in chat ${chatId}`);
      return;
    }

    // 3. Get sender's name (for notification title)
    const senderDoc = await admin.firestore()
        .collection("users")
        .doc(senderId)
        .get();

    const senderName = senderDoc.exists ?
        senderDoc.data().name || "Someone" :
        "Someone";

    // 4. Send notification to each participant
    for (const receiverId of receiverIds) {
      // Get receiver's FCM token
      const receiverDoc = await admin.firestore()
          .collection("users")
          .doc(receiverId)
          .get();

      if (!receiverDoc.exists) {
        console.log(`📭 Receiver ${receiverId} not found`);
        continue; // Skip to next receiver
      }

      const fcmToken = receiverDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`🔕 No FCM token for ${receiverId}`);
        continue; // Skip to next receiver
      }

      // 5. Prepare and send notification
      const payload = {
        token: fcmToken,
        notification: {
          title: `${senderName}: ${chatDoc.data().topic}`,
          body: message.text,
        },
        data: {
          type: "chat",
          chatId: chatId,
          senderId: senderId,
          messageId: messageId,
        },
        apns: {
          payload: {
            aps: {
              mutableContent: 1,
              sound: "default",
              category: "MESSAGE_CATEGORY",
            },
          },
        },
        android: {
          priority: "high",
          notification: {
            channelId: "MESSAGES_CHANNEL",
            sound: "default",
            icon: "ic_notification",
          },
        },
      };

      await admin.messaging().send(payload);
      console.log(`📨 Notification sent to ${receiverId}`);
    }
  } catch (error) {
    console.error("🔥 Critical error:", error);
  }
});

exports.inAppNotifiation = functions.firestore.onDocumentCreated(
    "users/{userId}/notification/{notificationId}",
    async (event, context) => {
      const message = event.data.data();
      const {userId, notificationId} = event.params;
      try {
        const userData = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();

        if (!userData.exists) {
          console.log("Data with userId not found");
          return;
        }

        const senderName = message.senderName;
        const senderId = message.senderId;
        const fcmToken = userData.data().fcmToken;
        const messageId = userId;

        if (!fcmToken) {
          console.log("No fcm token available");
        }

        const payload = {
          token: fcmToken,
          notification: {
            title: message.title,
            body: message.message,
          },
          data: {
            type: "vibe_points",
            senderName: senderName,
            senderId: senderId,
            notificationId: notificationId, // 🔥 Fixed: Use notificationId instead of messageId
            userId: userId,
            points: message.points?.toString() || "0",
          },
          apns: {
            payload: {
              aps: {
                mutableContent: 1,
                sound: "default",
                category: "MESSAGE_CATEGORY",
              },
            },
          },
          android: {
            priority: "high",
            notification: {
              channelId: "MESSAGES_CHANNEL",
              sound: "default",
              icon: "ic_notification",
            },
          },
        };
        await admin.messaging().send(payload);
        console.log(`📨 Notification sent to user ${userId}`);
      } catch (error) {
        console.error("Error:", error);
      }
    },
);

exports.sendGosipRequestNotificationToAdmin = functions.firestore.onDocumentUpdated(
    "gossipPendingRequests/{groupId}",
    async (event, context)=>{
      const groupId = event.params.groupId;
      // const userId = event.params.createdBy;
      const afterData = event.data.after.data();
      const beforeData = event.data.before.data();

      const oldRequests = beforeData.requests ||[];
      const newRequests = afterData.requests ||[];

      if (newRequests.length>oldRequests.length) {
        const latestRequest = newRequests[newRequests.length-1];
        const userId = latestRequest.requestBy;

        const groupDoc = await admin.firestore().collection("group_chats").doc(groupId).get();
        const creatorUid = groupDoc.data().creator;

        const creatorDoc = await admin.firestore().collection("users").doc(creatorUid).get();
        const fcmToken = creatorDoc.data().fcmToken;
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        const userName = userDoc.data().userName;
        if (fcmToken) {
          const payload ={
            notification: {
              title: "New Request for joinig the group",
              body: `${userName} Requested to join him in the Group`,

            },
            data: {
              senderId: String(userId),
              groupId: String(groupId),
              type: "join_request",
            },
            token: fcmToken,
          };
          await admin.messaging().send(payload);
          console.log("Notification sent to:", creatorUid);
        }
      }
    },
);

// exports.ApprovalRequesttoUser = functions.firestore.onDocumentUpdated(
//     "",
// );


// 🌐 2. Fetch News from API and Save to Firestore with `article_id` as doc ID
async function makeApiRequest() {
  try {
    const response = await axios.get("https://newsdata.io/api/1/news", {
      params: {
        apikey: "pub_8097417e016b36249e13f15d16473c640fcf4", // 🔑 Replace with your real API key
        language: "en",
        country: "in",
      },
      headers: {
        "Content-Type": "application/json",
      },
    });

    const newsList = response.data.results || [];
    const batch = admin.firestore().batch();

    newsList.forEach((newsItem) => {
      if (newsItem.article_id) {
        const docRef = admin.firestore().collection("NEWS").doc(newsItem.article_id);
        batch.set(docRef, {
          ...newsItem,
          timestamp: admin.firestore.Timestamp.now(),
        });
      }
    });

    await batch.commit();
    console.log(`✅ ${newsList.length} news items saved`);
  } catch (e) {
    console.error("❌ Error while fetching the API:", e);
  }
}

// 🗑️ 3. Delete News Older Than 26 Hours
async function deleteOldNews() {
  try {
    const newsRef = admin.firestore().collection("NEWS");
    const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 26 * 60 * 60 * 1000));
    const oldNews = await newsRef.where("timestamp", "<=", cutoff).get();

    if (oldNews.empty) {
      console.log("No old news to delete.");
      return;
    }

    const batch = admin.firestore().batch();
    oldNews.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
    console.log("🗑️ Old news deleted successfully");
  } catch (e) {
    console.error("❌ Error while deleting old news:", e);
  }
}

exports.scheduledNewsFetch = onSchedule("*/7 * * * *", async (event) => {
  await makeApiRequest();
});

exports.scheduledNewsCleanup = onSchedule("0 * * * *", async (event) => {
  await deleteOldNews();
});
