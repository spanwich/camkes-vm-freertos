#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { spawn } from 'child_process';

let qemuProcess = null;
let qemuInput = null;
let outputBuffer = '';

const server = new Server({
  name: "qemu-input-mcp",
  version: "1.0.0"
}, {
  capabilities: {
    tools: {}
  }
});

// Handle tools/list
server.setRequestHandler({
  method: "tools/list"
}, async () => {
  return {
    tools: [
      {
        name: "qemu_start",
        description: "Start QEMU with the ability to send input commands",
        inputSchema: {
          type: "object",
          properties: {
            command: { 
              type: "string", 
              description: "Full QEMU command to execute" 
            }
          },
          required: ["command"]
        }
      },
      {
        name: "qemu_input",
        description: "Send keyboard input to running QEMU process",
        inputSchema: {
          type: "object",
          properties: {
            input: { 
              type: "string", 
              description: "Text input to send to QEMU" 
            },
            special_key: { 
              type: "string", 
              description: "Special key combination",
              enum: ["ctrl-a-x", "ctrl-c", "enter", "esc", "tab"]
            }
          }
        }
      },
      {
        name: "qemu_monitor",
        description: "Send commands to QEMU monitor",
        inputSchema: {
          type: "object",
          properties: {
            command: { 
              type: "string", 
              description: "Monitor command to execute" 
            }
          },
          required: ["command"]
        }
      },
      {
        name: "qemu_stop",
        description: "Stop the running QEMU process",
        inputSchema: {
          type: "object",
          properties: {}
        }
      }
    ]
  };
});

// Handle tools/call
server.setRequestHandler({
  method: "tools/call"
}, async (request) => {
  const { name, arguments: args } = request.params;
  
  try {
    switch (name) {
      case 'qemu_start':
        return await startQemu(args.command);
      
      case 'qemu_input':
        return await sendInput(args.input, args.special_key);
      
      case 'qemu_monitor':
        return await sendMonitorCommand(args.command);
      
      case 'qemu_stop':
        return await stopQemu();
      
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{
        type: "text",
        text: `Error: ${error.message}`
      }],
      isError: true
    };
  }
});

async function startQemu(command) {
  if (qemuProcess) {
    qemuProcess.kill();
  }
  
  const cmdParts = command.split(' ');
  qemuProcess = spawn(cmdParts[0], cmdParts.slice(1), {
    stdio: ['pipe', 'pipe', 'pipe']
  });
  
  qemuInput = qemuProcess.stdin;
  outputBuffer = '';
  
  qemuProcess.stdout.on('data', (data) => {
    outputBuffer += data.toString();
  });
  
  qemuProcess.stderr.on('data', (data) => {
    outputBuffer += data.toString();
  });
  
  qemuProcess.on('exit', (code) => {
    qemuProcess = null;
    qemuInput = null;
  });
  
  // Wait for initial output
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  return {
    content: [{
      type: "text",
      text: `QEMU started successfully. Output:\n${outputBuffer}`
    }]
  };
}

async function sendInput(input, specialKey) {
  if (!qemuInput) {
    throw new Error("QEMU not running. Start QEMU first.");
  }
  
  let inputToSend = '';
  
  if (specialKey) {
    switch (specialKey) {
      case 'ctrl-a-x':
        inputToSend = '\x01x';
        break;
      case 'ctrl-c':
        inputToSend = '\x03';
        break;
      case 'enter':
        inputToSend = '\n';
        break;
      case 'esc':
        inputToSend = '\x1b';
        break;
      case 'tab':
        inputToSend = '\t';
        break;
    }
  } else if (input) {
    inputToSend = input;
  }
  
  qemuInput.write(inputToSend);
  
  // Wait a bit for response
  await new Promise(resolve => setTimeout(resolve, 500));
  
  return {
    content: [{
      type: "text",
      text: `Sent: ${specialKey || input}\nRecent output:\n${outputBuffer.slice(-1000)}`
    }]
  };
}

async function sendMonitorCommand(command) {
  if (!qemuInput) {
    throw new Error("QEMU not running. Start QEMU first.");
  }
  
  // Switch to monitor
  qemuInput.write('\x01c');
  await new Promise(resolve => setTimeout(resolve, 500));
  
  // Send command
  qemuInput.write(command + '\n');
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Return to console
  qemuInput.write('\x01c');
  
  return {
    content: [{
      type: "text",
      text: `Monitor command sent: ${command}\nOutput:\n${outputBuffer.slice(-1000)}`
    }]
  };
}

async function stopQemu() {
  if (qemuProcess) {
    qemuInput.write('\x01x'); // Ctrl+A, X
    
    setTimeout(() => {
      if (qemuProcess && !qemuProcess.killed) {
        qemuProcess.kill();
      }
    }, 2000);
    
    qemuProcess = null;
    qemuInput = null;
  }
  
  return {
    content: [{
      type: "text",
      text: "QEMU stopped"
    }]
  };
}

const transport = new StdioServerTransport();
await server.connect(transport);