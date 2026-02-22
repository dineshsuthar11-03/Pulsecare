const express = require('express');
const router = express.Router();
const consultationController = require('../controllers/consultationController');

// Send email notifications for a scheduled video consultation (includes Jitsi room info)
router.post('/notify', consultationController.sendScheduleEmails);

module.exports = router;
