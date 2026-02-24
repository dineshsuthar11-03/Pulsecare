const { createClient } = require('@supabase/supabase-js');
const nodemailer = require('nodemailer');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  },
);

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

exports.sendScheduleEmails = async (req, res) => {
  const { patientId, doctorId, scheduledAt, consultationId, roomCode } =
    req.body || {};

  if (!patientId || !doctorId || !scheduledAt) {
    return res.status(400).json({
      error: 'patientId, doctorId and scheduledAt are required.',
    });
  }

  try {
    const [patientResult, doctorResult] = await Promise.all([
      supabase.from('users').select('id, email, full_name').eq('id', patientId).single(),
      supabase.from('users').select('id, email, full_name').eq('id', doctorId).single(),
    ]);

    if (patientResult.error) throw patientResult.error;
    if (doctorResult.error) throw doctorResult.error;

    const patient = patientResult.data;
    const doctor = doctorResult.data;

    if (!patient?.email || !doctor?.email) {
      return res.status(400).json({ error: 'Missing email for patient or doctor.' });
    }

    const when = new Date(scheduledAt).toLocaleString('en-IN', {
      dateStyle: 'medium',
      timeStyle: 'short',
    });

    const subject = 'PulseCare Video Consultation Scheduled';

    // Build Jitsi meeting URL using JaaS app key namespace if provided.
    const jitsiAppKey =
      process.env.JITSI_APP_KEY || 'vpaas-magic-cookie-948f154a99304c5ba7989ca1f6055ef6';
    const safeRoomCode =
      roomCode || (consultationId ? `consult_${consultationId}` : undefined);
    const meetingUrl = safeRoomCode
      ? `https://8x8.vc/${jitsiAppKey}/${safeRoomCode}`
      : null;

    const joinInfo =
      meetingUrl && safeRoomCode
        ? `\n\nRoom code: ${safeRoomCode}\nIf needed, you can also join via this link: ${meetingUrl}`
        : '';

    const patientText = `Hello ${
      patient.full_name || 'Patient'
    },\n\nYour video consultation with Dr. ${
      doctor.full_name || 'Doctor'
    } has been scheduled for ${when}.${joinInfo}\n\nPlease open the PulseCare app at the scheduled time and tap on the consultation to join the video call.\n\nRegards,\nPulseCare Team`;

    const doctorText = `Hello Dr. ${
      doctor.full_name || ''
    },\n\nA new video consultation has been scheduled with patient ${
      patient.full_name || 'Patient'
    } for ${when}.${joinInfo}\n\nPlease open the PulseCare app at the scheduled time and start the video call from your consultations list.\n\nRegards,\nPulseCare Team`;

    const mails = [
      {
        from: process.env.EMAIL_USER,
        to: patient.email,
        subject,
        text: patientText,
      },
      {
        from: process.env.EMAIL_USER,
        to: doctor.email,
        subject,
        text: doctorText,
      },
    ];

    try {
      await Promise.all(mails.map((mail) => transporter.sendMail(mail)));
      console.log(
        `[ConsultationController] Schedule emails sent to ${patient.email} and ${doctor.email}`,
      );
      return res.json({ success: true });
    } catch (mailErr) {
      console.error(
        '[ConsultationController] Error sending schedule emails via Nodemailer:',
        mailErr,
      );
      return res.status(500).json({ error: 'Failed to send schedule emails.' });
    }
  } catch (err) {
    console.error('[ConsultationController] sendScheduleEmails error:', err.message || err);
    return res.status(500).json({ error: 'Failed to send schedule emails.' });
  }
};
