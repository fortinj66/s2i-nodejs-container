const http = require('http');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  const response = {
    message: 'Hello from Node.js!',
    version: process.version,
    npm: process.versions.npm,
    v8: process.versions.v8,
    platform: process.platform,
    arch: process.arch,
    timestamp: new Date().toISOString()
  };

  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response, null, 2));
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Node.js ${process.version}`);
});
