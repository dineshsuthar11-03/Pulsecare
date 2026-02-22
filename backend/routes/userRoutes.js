const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Get all users (for testing: http://localhost:5000/api/users)
router.get('/', userController.getAllUsers);

// Get all doctors
router.get('/doctors', userController.getDoctors);

// Get specific profile
router.get('/profile/:id', userController.getProfile);

module.exports = router;
