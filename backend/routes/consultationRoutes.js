const express = require('express');
const router = express.Router();
const consultationController = require('../controllers/consultationController');

// List consultations for a user
router.get('/', consultationController.getConsultations);

// Create a new consultation booking
router.post('/', consultationController.createConsultation);

// Doctor availability and slot lookup for patient booking
router.get('/doctor/:doctorId/availability', consultationController.getDoctorAvailability);
router.get('/doctor/:doctorId/slots', consultationController.getDoctorAvailableSlots);

// Update consultation status/notes/prescription
router.patch('/:id', consultationController.updateConsultation);

// Send email notifications for a scheduled video consultation (includes Jitsi room info)
router.post('/notify', consultationController.sendScheduleEmails);

module.exports = router;
