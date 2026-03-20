const { Resend } = require('resend');
const nodemailer = require('nodemailer');
require('dotenv').config();

const resend = process.env.RESEND_API_KEY
    ? new Resend(process.env.RESEND_API_KEY)
    : null;

let smtpTransporter = null;

const getSmtpCredentials = () => ({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: Number(process.env.SMTP_PORT || 587),
    secure: String(process.env.SMTP_SECURE || 'false').toLowerCase() === 'true',
    user: process.env.SMTP_USER || process.env.EMAIL_USER,
    pass: process.env.SMTP_PASS || process.env.EMAIL_PASS,
});

const getActiveProvider = () => {
    const explicitProvider = (process.env.EMAIL_PROVIDER || '').toLowerCase();

    if (explicitProvider === 'smtp' || explicitProvider === 'resend') {
        return explicitProvider;
    }

    const smtpCreds = getSmtpCredentials();
    if (smtpCreds.user && smtpCreds.pass) {
        return 'smtp';
    }

    return 'resend';
};

const getSmtpTransporter = () => {
    if (smtpTransporter) {
        return smtpTransporter;
    }

    const smtpCreds = getSmtpCredentials();
    if (!smtpCreds.user || !smtpCreds.pass) {
        throw new Error('SMTP credentials are not configured (SMTP_USER/SMTP_PASS).');
    }

    smtpTransporter = nodemailer.createTransport({
        host: smtpCreds.host,
        port: smtpCreds.port,
        secure: smtpCreds.secure,
        auth: {
            user: smtpCreds.user,
            pass: smtpCreds.pass,
        },
    });

    return smtpTransporter;
};

const getFromAddress = (provider) => {
    if (process.env.EMAIL_FROM) {
        return process.env.EMAIL_FROM;
    }

    if (provider === 'smtp') {
        return getSmtpCredentials().user;
    }

    return 'PulseCare <onboarding@resend.dev>';
};

const sendTextEmail = async ({ to, subject, text }) => {
    const recipients = Array.isArray(to) ? to : [to];
    const provider = getActiveProvider();

    if (provider === 'smtp') {
        const transporter = getSmtpTransporter();
        await transporter.sendMail({
            from: getFromAddress(provider),
            to: recipients,
            subject,
            text,
        });
        return;
    }

    if (!process.env.RESEND_API_KEY || !resend) {
        throw new Error('RESEND_API_KEY is not configured.');
    }

    const { error } = await resend.emails.send({
        from: getFromAddress(provider),
        to: recipients,
        subject,
        text,
    });

    if (error) {
        throw new Error(error.message || 'Failed to send email via Resend.');
    }
};

module.exports = {
    sendTextEmail,
    getFromAddress,
};