require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./src/config/db');

const app = express();
const httpServer = http.createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*' }
});

// Connect DB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());

// Routes (we'll fill these in coming steps)
app.use('/api/auth',         require('./src/routes/auth'));
app.use('/api/hospitals',    require('./src/routes/hospitals'));
app.use('/api/doctors',      require('./src/routes/doctors'));
app.use('/api/appointments', require('./src/routes/appointments'));
app.use('/api/queue',        require('./src/routes/queue'));

// Health check
app.get('/', (req, res) => res.json({ message: 'MediQueue API running' }));

// Make io accessible in routes
app.set('io', io);

// Socket.io
require('./src/socket/queueSocket')(io);

const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, () => console.log(`Server running on port ${PORT}`));