require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./src/config/db');
const path = require('path');

const app = express();
const httpServer = http.createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*' }
});

// Connect DB
connectDB();

// Middleware
app.use(cors({
  origin: ['https://mediqueue-admin-portal.netlify.app', 'http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  credentials: true,
}));
app.use(express.json());
// Serve admin dashboard
app.use(express.static('public'));

// Routes (we'll fill these in coming steps)
app.use('/api/auth',         require('./src/routes/auth'));
app.use('/api/hospitals',    require('./src/routes/hospitals'));
app.use('/api/doctors',      require('./src/routes/doctors'));
app.use('/api/appointments', require('./src/routes/appointments'));
app.use('/api/queue',        require('./src/routes/queue'));
app.use('/api/ai', require('./src/routes/ai'));

// Serve index.html at root
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check
app.get('/', (req, res) => res.json({ message: 'MediQueue API running' }));

// Make io accessible in routes
app.set('io', io);

// Health check route to keep the server awake
app.get('/ping', (req, res) => res.status(200).send('Pong! Server is awake.'));

// Socket.io
require('./src/socket/queueSocket')(io);

const PORT = process.env.PORT || 5000;
httpServer.listen(PORT,'0.0.0.0', () => console.log(`Server running on port ${PORT}`));
