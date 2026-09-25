const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { AccessToken } = require("livekit-server-sdk");

// Set these via: firebase functions:config:set livekit.key="..." livekit.secret="..."
// or (v2 preferred) firebase functions:secrets:set LIVEKIT_API_KEY / LIVEKIT_API_SECRET
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;

exports.generateLiveKitToken = onCall(
  { secrets: ["LIVEKIT_API_KEY", "LIVEKIT_API_SECRET"] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { roomName } = request.data;
    if (!roomName || typeof roomName !== "string") {
      throw new HttpsError("invalid-argument", "roomName is required.");
    }

    // request.auth.uid is trusted, verified server-side by Firebase
    // Auth — the client cannot spoof this, which is exactly why token
    // generation must happen here and not on-device.
    const token = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: request.auth.uid,
    });
    token.addGrant({ roomJoin: true, room: roomName });

    return { token: await token.toJwt() };
  }
);