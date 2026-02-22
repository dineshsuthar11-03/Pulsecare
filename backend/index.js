const express = require('express');
const cors = require('cors');
require('dotenv').config();
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const symptomRoutes = require('./routes/symptomRoutes');
const aiRoutes = require('./routes/aiRoutes');
const medicineRoutes = require('./routes/medicineRoutes');
const consultationRoutes = require('./routes/consultationRoutes');
const db = require('./config/db');

const app = express();

// Global Error Handler for uncaught exceptions
process.on('uncaughtException', (err) => {
    console.error('CRITICAL: Uncaught Exception:', err.message);
    console.error(err.stack);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('CRITICAL: Unhandled Rejection at:', promise, 'reason:', reason);
});

// Middleware
app.use(cors());
app.use(express.json());

// Request Logger - VERY IMPORTANT FOR DEBUGGING
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} request to: ${req.url}`);
    next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/symptoms', symptomRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/medicines', medicineRoutes);
app.use('/api/consultations', consultationRoutes);

// Health Check
app.get('/', (req, res) => {
    console.log('--- Health Check Ping Received ---');
    res.send('PulseCare API is running...');
});

app.use((err, req, res, next) => {
    console.error('SERVER ERROR:', err.stack);
    res.status(500).send('Something broke!');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`-------------------------------------------`);
    console.log(`🚀 PulseCare Backend Live on Port ${PORT}`);
    console.log(`📍 Test URL: http://localhost:${PORT}/api/users`);
    console.log(`-------------------------------------------`);
});
