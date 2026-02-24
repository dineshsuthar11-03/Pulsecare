const { createClient } = require('@supabase/supabase-js');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
require('dotenv').config();

// Initialize Supabase Admin Client
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
        auth: {
            autoRefreshToken: false,
            persistSession: false,
        },
    }
);

// Configure NodeMailer for Gmail SMTP
// This explicit SMTP config tends to be more reliable on hosts like Railway
// than the generic `service: 'gmail'` shortcut.
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false, // use STARTTLS
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

// Generate a 6-digit numeric OTP
const generateOtp = () =>
    Math.floor(100000 + Math.random() * 900000).toString();

// Create and email an OTP code for a given email
const createAndSendOtp = async (email, subject, introText) => {
    const otp = generateOtp();
    const otpHash = await bcrypt.hash(otp, 10);

    // Optional: clean up existing OTPs for this email
    await supabase.from('otp_codes').delete().eq('email', email);

    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString(); // 10 minutes

    const { error: insertError } = await supabase.from('otp_codes').insert({
        email,
        otp_hash: otpHash,
        expires_at: expiresAt,
    });

    if (insertError) {
        console.error('Error inserting OTP record:', insertError.message);
        throw new Error('Failed to create OTP. Please try again.');
    }

    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject,
        text: `${introText}\n\nYour One-Time Password (OTP) is: ${otp}\n\nThis code will expire in 10 minutes. If you did not request this, you can ignore this email.`,
    };

    await transporter.sendMail(mailOptions);
};

// Helper to verify an OTP for a given email and consume it
const verifyAndConsumeOtp = async (email, otp) => {
    const { data, error } = await supabase
        .from('otp_codes')
        .select('*')
        .eq('email', email)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

    if (error) {
        console.error('Error fetching OTP record:', error.message);
        throw new Error('Failed to verify OTP. Please try again.');
    }

    if (!data) {
        throw new Error('No OTP request found for this email.');
    }

    const now = new Date();
    const expiresAt = new Date(data.expires_at);

    if (now > expiresAt) {
        // Remove expired record
        await supabase.from('otp_codes').delete().eq('id', data.id);
        throw new Error('This OTP has expired. Please request a new one.');
    }

    if (data.attempts >= 5) {
        throw new Error('Too many invalid attempts. Please request a new OTP.');
    }

    const isValid = await bcrypt.compare(otp, data.otp_hash);

    if (!isValid) {
        await supabase
            .from('otp_codes')
            .update({ attempts: data.attempts + 1 })
            .eq('id', data.id);
        throw new Error('Invalid OTP. Please try again.');
    }

    // OTP is valid; consume it
    await supabase.from('otp_codes').delete().eq('id', data.id);
};

// Find a Supabase auth user by email using Admin API
const findAuthUserByEmail = async (email) => {
    const { data, error } = await supabase.auth.admin.listUsers();

    if (error) {
        console.error('Error listing users:', error.message);
        throw new Error('Failed to look up user.');
    }

    const user = data?.users?.find((u) => u.email === email) || null;
    return user;
};

exports.signup = async (req, res) => {
    const { email, password, full_name, role } = req.body;

    try {
        // 1. Create user in Supabase Auth (This triggers the handle_new_user function in SQL)
        const { data, error } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: false, // require OTP-based verification
            user_metadata: {
                full_name: full_name,
                role: role || 'patient',
            },
        });

        if (error) {
            console.error('Supabase Auth Error:', error.message);
            return res.status(400).json({ error: error.message });
        }

        // 2. Send OTP email for signup verification
        try {
            await createAndSendOtp(
                email,
                'Verify your PulseCare account',
                `Hello ${full_name},\n\nThank you for registering with PulseCare. To verify your account and start using the app, please use the OTP below.`,
            );
        } catch (mailError) {
            console.error('Signup OTP email error:', mailError.message);
            return res.status(500).json({
                error:
                    'Account created, but failed to send verification OTP email. Please try again.',
            });
        }

        res.status(201).json({
            message:
                'User registered successfully. An OTP has been sent to your email for verification.',
            user: data.user,
        });

    } catch (err) {
        console.error('Server Error:', err);
        res.status(500).json({ error: 'Internal server error during registration' });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        // Authenticate with Supabase
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });

        if (error) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Generate our own custom JWT for the backend if needed, 
        // or just pass the Supabase session
        const token = jwt.sign(
            { id: data.user.id, email: data.user.email },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            message: 'Login successful',
            token,
            user: data.user,
            session: data.session // This contains access_token and refresh_token
        });

    } catch (err) {
        console.error('Login Error:', err);
        res.status(500).json({ error: 'Server error during login' });
    }
};
// Request a password reset OTP via email
exports.forgotPassword = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ error: 'Email is required.' });
    }

    try {
        await createAndSendOtp(
            email,
            'PulseCare password reset OTP',
            'We received a request to reset your PulseCare account password. Use the OTP below to proceed.',
        );

        res.json({
            message: 'Password reset OTP sent to your email.',
        });
    } catch (err) {
        console.error('Forgot password error:', err.message || err);
        res
            .status(500)
            .json({ error: 'Failed to send password reset OTP. Please try again.' });
    }
};

// Resend signup verification OTP
exports.resendSignupOtp = async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ error: 'Email is required.' });
    }

    try {
        await createAndSendOtp(
            email,
            'Verify your PulseCare account',
            'To verify your PulseCare account, please use the OTP below.',
        );

        res.json({ message: 'Verification OTP resent to your email.' });
    } catch (err) {
        console.error('resendSignupOtp error:', err.message || err);
        res
            .status(500)
            .json({ error: 'Failed to resend verification OTP. Please try again.' });
    }
};

// Verify signup OTP and mark user email as confirmed
exports.verifySignupOtp = async (req, res) => {
    const { email, otp } = req.body;

    if (!email || !otp) {
        return res.status(400).json({ error: 'Email and OTP are required.' });
    }

    try {
        await verifyAndConsumeOtp(email, otp);

        const user = await findAuthUserByEmail(email);
        if (!user) {
            return res
                .status(404)
                .json({ error: 'User not found for this email address.' });
        }

        const { error: updateError } = await supabase.auth.admin.updateUserById(
            user.id,
            {
                email_confirm: true,
            }
        );

        if (updateError) {
            console.error('Error confirming email:', updateError.message);
            return res
                .status(500)
                .json({ error: 'Failed to verify email. Please try again.' });
        }

        // Optional: send a welcome/confirmation email
        try {
            await transporter.sendMail({
                from: process.env.EMAIL_USER,
                to: email,
                subject: 'Your PulseCare account is verified',
                text:
                    'Your email has been successfully verified. You can now log in to PulseCare and start using the app.',
            });
        } catch (mailError) {
            console.error('Post-verification email error:', mailError.message);
        }

        res.json({ message: 'Email verified successfully.' });
    } catch (err) {
        console.error('verifySignupOtp error:', err.message || err);
        res.status(400).json({ error: err.message || 'Invalid or expired OTP.' });
    }
};

// Reset password using OTP (no Supabase email-based flow)
exports.resetPasswordWithOtp = async (req, res) => {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
        return res
            .status(400)
            .json({ error: 'Email, OTP, and new password are required.' });
    }

    try {
        await verifyAndConsumeOtp(email, otp);

        const user = await findAuthUserByEmail(email);
        if (!user) {
            return res
                .status(404)
                .json({ error: 'User not found for this email address.' });
        }

        const { error: updateError } = await supabase.auth.admin.updateUserById(
            user.id,
            {
                password: newPassword,
            }
        );

        if (updateError) {
            console.error('Error updating password:', updateError.message);
            return res
                .status(500)
                .json({ error: 'Failed to reset password. Please try again.' });
        }

        try {
            await transporter.sendMail({
                from: process.env.EMAIL_USER,
                to: email,
                subject: 'Your PulseCare password was changed',
                text:
                    'Your PulseCare account password has been successfully reset. If you did not perform this action, please contact support immediately.',
            });
        } catch (mailError) {
            console.error('Password reset confirmation email error:', mailError.message);
        }

        res.json({ message: 'Password reset successfully.' });
    } catch (err) {
        console.error('resetPasswordWithOtp error:', err.message || err);
        res.status(400).json({ error: err.message || 'Invalid or expired OTP.' });
    }
};
