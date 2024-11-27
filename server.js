const express = require('express');
const bodyParser = require('body-parser');
const { spawn } = require('child_process');
const path = require('path');
const http = require('http');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

const log = (message) => {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${message}`);
    return `[${timestamp}] ${message}`;
};

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.post('/download', (req, res) => {
    const urls = req.body.urls.filter(url => url.trim().startsWith('http'));

    if (urls.length === 0) {
        return res.status(400).send('No valid URLs provided');
    }

    const downloadDir = '/downloads';
    const command = `tdl dl -d ${downloadDir} ${urls.map(url => `-u ${url}`).join(' ')}`;
    log(`Executing command: ${command}`);

    const tdl = spawn('tdl', ['dl', '-d', downloadDir, ...urls.flatMap(url => ['-u', url])]);

    const stripAnsi = (str) => str.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, '');

    let lastProgressLine = '';

    function processOutput(data) {
        const lines = stripAnsi(data.toString()).split('\n');
        lines.forEach(line => {
            const trimmedLine = line.trim();
            if (trimmedLine && trimmedLine.includes('%')) {
                lastProgressLine = trimmedLine;
                wss.clients.forEach((client) => {
                    if (client.readyState === WebSocket.OPEN) {
                        client.send(lastProgressLine);
                    }
                });
            }
        });
    }

    tdl.stdout.on('data', processOutput);
    tdl.stderr.on('data', processOutput);

    tdl.on('error', (error) => {
        console.error(`Error: ${error.message}`);
    });

    wss.on('connection', (ws) => {
        console.log('WebSocket connection established');
        ws.on('message', (message) => {
            console.log('Received message:', message);
        });
    });

    tdl.on('close', (code) => {
        if (code !== 0) {
            const logMessage = log(`Download process exited with code: ${code}`);
            wss.clients.forEach((client) => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(logMessage);
                }
            });
        }
    });

    res.send('Download started');
});

server.listen(PORT, () => {
    log(`Server is running on http://localhost:${PORT}`)
});
