const { Resend } = require('resend');
const nodemailer = require('nodemailer');
require('dotenv').config();

const resend = process.env.RESEND_API_KEY
    ? new Resend(process.env.RESEND_API_KEY)
    : null;

let smtpTransporter = null;
const EMAIL_SEND_TIMEOUT_MS = Number(process.env.EMAIL_SEND_TIMEOUT_MS || 15000);

const withTimeout = async (promise, timeoutMs, timeoutMessage) => {
    let timeoutHandle;
    const timeoutPromise = new Promise((_, reject) => {
        timeoutHandle = setTimeout(() => {
            reject(new Error(timeoutMessage));
        }, timeoutMs);
    });

    try {
        return await Promise.race([promise, timeoutPromise]);
    } finally {
        clearTimeout(timeoutHandle);
    }
};

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
        connectionTimeout: EMAIL_SEND_TIMEOUT_MS,
        greetingTimeout: EMAIL_SEND_TIMEOUT_MS,
        socketTimeout: EMAIL_SEND_TIMEOUT_MS,
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
        try {
            const transporter = getSmtpTransporter();
            await withTimeout(
                transporter.sendMail({
                    from: getFromAddress(provider),
                    to: recipients,
                    subject,
                    text,
                }),
                EMAIL_SEND_TIMEOUT_MS,
                'SMTP email request timed out.',
            );
            return;
        } catch (smtpErr) {
            // Automatic fallback to Resend when SMTP is configured but currently failing.
            if (process.env.RESEND_API_KEY && resend) {
                const { error } = await withTimeout(
                    resend.emails.send({
                        from: getFromAddress('resend'),
                        to: recipients,
                        subject,
                        text,
                    }),
                    EMAIL_SEND_TIMEOUT_MS,
                    'Resend email request timed out.',
                );

                if (error) {
                    throw new Error(error.message || 'Failed to send email via Resend fallback.');
                }

                return;
            }

            throw smtpErr;
        }
    }

    if (!process.env.RESEND_API_KEY || !resend) {
        throw new Error('RESEND_API_KEY is not configured.');
    }

    const { error } = await withTimeout(
        resend.emails.send({
            from: getFromAddress(provider),
            to: recipients,
            subject,
            text,
        }),
        EMAIL_SEND_TIMEOUT_MS,
        'Resend email request timed out.',
    );

    if (error) {
        throw new Error(error.message || 'Failed to send email via Resend.');
    }
};

module.exports = {
    sendTextEmail,
    getFromAddress,
};