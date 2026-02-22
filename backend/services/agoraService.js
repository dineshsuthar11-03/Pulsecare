const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

function generateRtcToken({ channelName, uid = 0, role = 'publisher', expireSeconds = 3600 }) {
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;

  if (!appId) {
    throw new Error('AGORA_APP_ID is not set');
  }

  if (!appCertificate) {
    throw new Error('AGORA_APP_CERTIFICATE is not set');
  }

  const agoraRole = role === 'subscriber' ? RtcRole.SUBSCRIBER : RtcRole.PUBLISHER;

  const currentTs = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTs + expireSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    agoraRole,
    privilegeExpiredTs,
  );

  return {
    token,
    appId,
    channelName,
    uid,
    role: agoraRole,
    expireAt: privilegeExpiredTs,
  };
}

module.exports = {
  generateRtcToken,
};
