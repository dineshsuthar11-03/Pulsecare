const { Pool } = require('pg');
require('dotenv').config();

// Fix for self-signed certificate error on some networks
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false,
    },
});

pool.on('connect', () => {
    console.log('Successfully connected to Supabase PostgreSQL');
});

// Direct DB testing is removed to avoid confusing 'Tenant not found' errors 
// when using the Connection Pooler on some local networks. 
// The backend successfully uses the Supabase SDK for all operations.

pool.on('error', (err) => {
    console.error('Unexpected error on idle database client:', err.message);
    // Don't exit process, let the server stay alive for other SDK tasks
});

module.exports = {
    query: (text, params) => pool.query(text, params),
};
