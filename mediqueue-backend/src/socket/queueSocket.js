module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id);

    // Patient or admin joins a doctor's queue room
    socket.on('joinQueue', (doctorId) => {
      socket.join(`queue:${doctorId}`);
      console.log(`Socket ${socket.id} joined queue:${doctorId}`);
    });

    socket.on('leaveQueue', (doctorId) => {
      socket.leave(`queue:${doctorId}`);
      console.log(`Socket ${socket.id} left queue:${doctorId}`);
    });

    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id);
    });
  });
};