const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Simple health check for the auth routes
// @route GET /api/auth
router.get('/', (req, res) => {
	res.json({
		status: 'ok',
		message: 'Auth routes are mounted. Use POST /signup, /login, etc.',
	});
});

// @route POST /api/auth/signup
router.post('/signup', authController.signup);

// @route POST /api/auth/login
router.post('/login', authController.login);

// @route POST /api/auth/forgot-password
router.post('/forgot-password', authController.forgotPassword);

// @route POST /api/auth/verify-signup-otp
router.post('/verify-signup-otp', authController.verifySignupOtp);

// @route POST /api/auth/resend-signup-otp
router.post('/resend-signup-otp', authController.resendSignupOtp);

// @route POST /api/auth/reset-password-with-otp
router.post('/reset-password-with-otp', authController.resetPasswordWithOtp);

module.exports = router;
