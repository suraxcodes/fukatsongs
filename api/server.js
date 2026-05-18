// api/server.js - Hosted on Render.com or other Node.js environments
const express = require('express');
const cors = require('cors');
const streamHandler = require('./stream');

const app = express();

// Enable Cross-Origin Resource Sharing (CORS) so the Flutter client can communicate with this proxy
app.use(cors());

// A simple health check endpoint to prevent the Render instance from spinning down or to monitor uptime
app.get('/health', (req, res) => {
  res.status(200).send('Proxy server is up and running healthy.');
});

// Map the stream decryption handler to the /api/stream endpoint
// This ensures that the exact same API structure is preserved across both Vercel and Render!
app.get('/api/stream', streamHandler);

// Capture fallback/undefined routes with a friendly informational response
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: 'Valid endpoint is GET /api/stream?id=YOUR_YOUTUBE_VIDEO_ID',
    health: '/health'
  });
});

// Start listening on process.env.PORT provided dynamically by Render (defaults to 3000)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 fukatSongs Stream Proxy Server running on port ${PORT}`);
});
