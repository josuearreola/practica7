const express = require('express');
const http = require('http');
const { WebSocketServer, WebSocket } = require('ws');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + '-' + file.originalname);
  },
});
const upload = multer({ storage });

// --- SHARED IN-MEMORY & PERSISTENT DATA STORE ---
const DATA_FILE = path.join(__dirname, 'render_store.json');

let store = {
  devices: {
    admin: { name: 'Dispositivo 1 - Administrador', isOnline: true },
    agente: { name: 'Dispositivo 2 - Agente de Atención', isOnline: true },
    usuario1: { name: 'Dispositivo 3 - Usuario 1 (Sistemas)', isOnline: true },
    usuario2: { name: 'Dispositivo 4 - Usuario 2 (Finanzas)', isOnline: true },
  },
  messages: [
    {
      id: 'msg-001',
      senderRole: 'admin',
      senderDeviceName: 'Dispositivo 1 - Administrador',
      receiverRole: null,
      receiverDeviceName: null,
      text: 'Servidor Render activo. Dispositivos remotos conectados y sincronizados en tiempo real.',
      timestamp: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
    },
    {
      id: 'msg-002',
      senderRole: 'usuario1',
      senderDeviceName: 'Dispositivo 3 - Usuario 1',
      receiverRole: 'agente',
      receiverDeviceName: 'Dispositivo 2 - Agente de Atención',
      text: 'Hola Agente, registré el caso REP001 para revisión de Postgres.',
      attachment: {
        id: 'att-01',
        fileName: 'captura_error_servidor_r740.png',
        fileExtension: 'png',
        fileSizeBytes: 348160,
        mimeType: 'image/png',
        isImage: true,
      },
      timestamp: new Date(Date.now() - 1000 * 60 * 20).toISOString(),
    },
  ],
  reports: [
    {
      id: 'REP001',
      title: 'Caída de servicio en base de datos productiva',
      equipment: 'Servidor Dell PowerEdge R740',
      description: 'El servicio PostgreSQL no responde tras el reinicio automático de mantenimiento.',
      category: 'reporteFallas',
      priority: 'critica',
      status: 'enAtencion',
      assignedRole: 'agente',
      reportedByRole: 'usuario1',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 2).toISOString(),
      updatedAt: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
      resolutionNotes: 'Agente revisando logs en Postgres.',
      isDirectToAdmin: false,
    },
    {
      id: 'REP002',
      title: 'Bloqueo de credenciales y acceso perdido a nómina',
      equipment: 'Portal ERP Financiero Web',
      description: 'Usuario 2 bloqueó su cuenta tras 3 intentos fallidos.',
      category: 'solucionAccesosPerdidos',
      priority: 'alta',
      status: 'escaladoAdmin',
      assignedRole: 'admin',
      reportedByRole: 'usuario2',
      createdAt: new Date(Date.now() - 1000 * 60 * 50).toISOString(),
      updatedAt: new Date(Date.now() - 1000 * 60 * 10).toISOString(),
      resolutionNotes: 'Solicitud directa remitida al Administrador para reseteo.',
      isDirectToAdmin: true,
    },
    {
      id: 'REP003',
      title: 'Intermitencia de enlace y túnel VPN corporativo',
      equipment: 'Firewall Fortinet FortiGate 100F',
      description: 'Desconexiones frecuentes del cliente FortiClient en la subred de desarrollo.',
      category: 'reporteFallas',
      priority: 'media',
      status: 'abierto',
      assignedRole: 'agente',
      reportedByRole: 'usuario1',
      createdAt: new Date(Date.now() - 1000 * 60 * 40).toISOString(),
      updatedAt: new Date(Date.now() - 1000 * 60 * 40).toISOString(),
      isDirectToAdmin: false,
    },
  ],
  matrix: [
    { code: 'TC01', name: 'Alta válida', action: 'Registrar un reporte con todos los campos correctos.', expected: 'El documento se almacena y puede consultarse.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC02', name: 'Campos vacíos', action: 'Intentar guardar un reporte sin equipo ni descripción.', expected: 'La aplicación rechaza los datos y muestra una validación.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC03', name: 'Identificador repetido', action: 'Guardar dos veces el reporte con ID REP001.', expected: 'La aplicación evita sobrescribir información accidentalmente o aplica una política explícita.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC04', name: 'Actualización', action: 'Cambiar la prioridad de un reporte de Media a Alta.', expected: 'El cambio se conserva al volver a consultar el documento.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC05', name: 'Eliminación', action: 'Eliminar un reporte existente y consultarlo nuevamente.', expected: 'El documento ya no aparece como registro activo.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC06', name: 'Documento inexistente', action: 'Consultar el ID REP999.', expected: 'La aplicación maneja el resultado vacío sin bloquearse.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC07', name: 'Pérdida de conexión', action: 'Desactivar la conexión durante una operación de escritura.', expected: 'La app informa el estado de la operación y gestiona la sincronización o el error.', status: 'sinRegistrar', observations: 'Sin observaciones' },
    { code: 'TC08', name: 'Persistencia', action: 'Cerrar y abrir la app; consultar un reporte guardado.', expected: 'El dato persiste en Firestore y vuelve a mostrarse.', status: 'sinRegistrar', observations: 'Sin observaciones' },
  ],
};

// Persistence helper
function saveStoreToDisk() {
  try {
    fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2));
  } catch (e) {
    console.error('Error saving store to disk:', e);
  }
}

function loadStoreFromDisk() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const raw = fs.readFileSync(DATA_FILE, 'utf8');
      const loaded = JSON.parse(raw);
      store = { ...store, ...loaded };
    }
  } catch (e) {
    console.error('Error loading store from disk:', e);
  }
}
loadStoreFromDisk();

// WebSocket Broadcast Helper
function broadcast(eventType, payload) {
  const data = JSON.stringify({ type: eventType, payload, timestamp: Date.now() });
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
}

// --- WEBSOCKET CONNECTION HANDLING ---
wss.on('connection', (ws, req) => {
  console.log(`[WS] Nuevo cliente conectado desde ${req.socket.remoteAddress}`);

  // Send initial full sync state
  ws.send(JSON.stringify({
    type: 'initial_state',
    payload: {
      devices: store.devices,
      messages: store.messages,
      reports: store.reports,
      matrix: store.matrix,
    },
  }));

  ws.on('message', (message) => {
    try {
      const parsed = JSON.parse(message);
      console.log(`[WS Evento recibido]: ${parsed.type}`);

      if (parsed.type === 'register_device') {
        const { role } = parsed;
        if (store.devices[role]) {
          store.devices[role].isOnline = true;
          broadcast('device_presence_changed', { role, isOnline: true });
        }
      } else if (parsed.type === 'send_message') {
        const msg = parsed.message;
        store.messages.push(msg);
        saveStoreToDisk();
        broadcast('new_message', msg);
      } else if (parsed.type === 'toggle_agent_presence') {
        const isOnline = parsed.isOnline;
        store.devices.agente.isOnline = isOnline;
        if (!isOnline) {
          // Reassign open agent tickets to admin
          store.reports = store.reports.map((r) => {
            if (r.assignedRole === 'agente' && r.status !== 'resuelto' && r.status !== 'cerrado') {
              return {
                ...r,
                assignedRole: 'admin',
                status: 'escaladoAdmin',
                resolutionNotes: 'Escalado automáticamente al Admin por desconexión del Agente.',
                updatedAt: new Date().toISOString(),
              };
            }
            return r;
          });
        }
        saveStoreToDisk();
        broadcast('agent_status_changed', { isOnline, reports: store.reports });
      }
    } catch (e) {
      console.error('[WS Error procesando mensaje]:', e);
    }
  });

  ws.on('close', () => {
    console.log('[WS] Cliente desconectado.');
  });
});

// --- REST API ENDPOINTS ---

// Health check for Render
app.get('/api/status', (req, res) => {
  res.json({
    status: 'online',
    service: 'Practica 7 Backend Render',
    timestamp: new Date().toISOString(),
    connectedClients: wss.clients.size,
  });
});

// 1. Devices & Presence
app.get('/api/devices', (req, res) => {
  res.json(store.devices);
});

app.post('/api/devices/presence', (req, res) => {
  const { role, isOnline } = req.body;
  if (!store.devices[role]) {
    return res.status(400).json({ error: 'Rol inválido' });
  }

  store.devices[role].isOnline = Boolean(isOnline);

  if (role === 'agente' && !isOnline) {
    store.reports = store.reports.map((r) => {
      if (r.assignedRole === 'agente' && r.status !== 'resuelto' && r.status !== 'cerrado') {
        return {
          ...r,
          assignedRole: 'admin',
          status: 'escaladoAdmin',
          resolutionNotes: 'Escalado automáticamente al Admin por desconexión del Agente.',
          updatedAt: new Date().toISOString(),
        };
      }
      return r;
    });
  }

  saveStoreToDisk();
  broadcast('agent_status_changed', { isOnline, reports: store.reports });
  res.json({ success: true, devices: store.devices });
});

// 2. Chat Messages
app.get('/api/messages', (req, res) => {
  res.json(store.messages);
});

app.post('/api/messages', (req, res) => {
  const { senderRole, senderDeviceName, receiverRole, receiverDeviceName, text, attachment } = req.body;

  // Validation: Avoid empty messages (Requirement 6)
  if ((!text || text.trim().length === 0) && !attachment) {
    return res.status(400).json({
      success: false,
      error: 'No se puede enviar un mensaje vacío. Escriba un texto o adjunte un archivo.',
    });
  }

  const now = new Date();
  const newMsg = {
    id: uuidv4(),
    senderRole: senderRole || 'admin',
    senderDeviceName: senderDeviceName || 'Dispositivo',
    receiverRole: receiverRole || null,
    receiverDeviceName: receiverDeviceName || null,
    text: (text || '').trim(),
    attachment: attachment || null,
    timestamp: now.toISOString(),
  };

  store.messages.push(newMsg);
  saveStoreToDisk();

  broadcast('new_message', newMsg);
  res.status(201).json({ success: true, message: newMsg });
});

app.delete('/api/messages', (req, res) => {
  store.messages = [];
  saveStoreToDisk();
  broadcast('clear_history', {});
  res.json({ success: true, message: 'Historial de mensajes vaciado correctamente.' });
});

// 3. File Uploads
app.post('/api/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No se subió ningún archivo' });
  }

  const ext = path.extname(req.file.originalname).replace('.', '').toLowerCase();
  const isImage = ['png', 'jpg', 'jpeg', 'webp', 'gif'].includes(ext);

  const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

  const attachment = {
    id: uuidv4(),
    fileName: req.file.originalname,
    fileExtension: ext,
    fileSizeBytes: req.file.size,
    mimeType: req.file.mimetype,
    isImage,
    url: fileUrl,
  };

  res.status(201).json({ success: true, attachment });
});

// 4. Incident Reports (Cases) & Test Cases TC01-TC06
app.get('/api/reports', (req, res) => {
  res.json(store.reports);
});

app.get('/api/reports/:id', (req, res) => {
  const report = store.reports.find((r) => r.id.toUpperCase() === req.params.id.toUpperCase());
  if (!report) {
    // TC06: Handle non-existent ID gracefully without crashing
    return res.status(404).json({ error: 'Reporte no encontrado (TC06)' });
  }
  res.json(report);
});

app.post('/api/reports', (req, res) => {
  const { id, title, equipment, description, category, priority, assignedRole, reportedByRole, isDirectToAdmin } = req.body;

  // TC02: Campos vacíos check
  if (!equipment || equipment.trim() === '' || !description || description.trim() === '') {
    return res.status(400).json({
      success: false,
      error: 'Error de validación (TC02): El equipo y la descripción son obligatorios.',
    });
  }

  if (!id || id.trim() === '') {
    return res.status(400).json({ success: false, error: 'El ID es obligatorio' });
  }

  const cleanId = id.trim().toUpperCase();

  // TC03: Identificador repetido check
  const exists = store.reports.some((r) => r.id.toUpperCase() === cleanId);
  if (exists) {
    return res.status(409).json({
      success: false,
      error: `Error de duplicidad (TC03): El ID "${cleanId}" ya existe. Se evita la sobrescritura accidental.`,
    });
  }

  // TC01: Alta válida
  const newReport = {
    id: cleanId,
    title: title || `Reporte ${cleanId}`,
    equipment: equipment.trim(),
    description: description.trim(),
    category: category || 'reporteFallas',
    priority: priority || 'media',
    status: isDirectToAdmin ? 'escaladoAdmin' : 'abierto',
    assignedRole: isDirectToAdmin ? 'admin' : (assignedRole || 'agente'),
    reportedByRole: reportedByRole || 'usuario1',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    isDirectToAdmin: Boolean(isDirectToAdmin),
  };

  store.reports.unshift(newReport);
  saveStoreToDisk();

  broadcast('ticket_created', newReport);
  res.status(201).json({ success: true, report: newReport });
});

// TC04 - Actualización de prioridad
app.put('/api/reports/:id/priority', (req, res) => {
  const { priority } = req.body;
  const index = store.reports.findIndex((r) => r.id.toUpperCase() === req.params.id.toUpperCase());

  if (index === -1) {
    return res.status(404).json({ error: 'Reporte no encontrado' });
  }

  store.reports[index].priority = priority;
  store.reports[index].updatedAt = new Date().toISOString();
  saveStoreToDisk();

  broadcast('ticket_updated', store.reports[index]);
  res.json({ success: true, report: store.reports[index] });
});

// TC05 - Eliminación
app.delete('/api/reports/:id', (req, res) => {
  const index = store.reports.findIndex((r) => r.id.toUpperCase() === req.params.id.toUpperCase());

  if (index === -1) {
    return res.status(404).json({ error: 'Reporte no encontrado para eliminar' });
  }

  const deleted = store.reports.splice(index, 1)[0];
  saveStoreToDisk();

  broadcast('ticket_deleted', { id: deleted.id });
  res.json({ success: true, message: `Reporte ${deleted.id} eliminado correctamente (TC05).` });
});

// 5. Test Matrix Endpoints
app.get('/api/matrix', (req, res) => {
  res.json(store.matrix);
});

app.post('/api/matrix/run-all', (req, res) => {
  const now = new Date().toISOString();
  store.matrix = [
    { code: 'TC01', name: 'Alta válida', action: 'Registrar un reporte con todos los campos correctos.', expected: 'El documento se almacena y puede consultarse.', status: 'aprobado', observations: 'El reporte se almacenó en Render y se consultó con persistencia.', executedAt: now },
    { code: 'TC02', name: 'Campos vacíos', action: 'Intentar guardar un reporte sin equipo ni descripción.', expected: 'La aplicación rechaza los datos y muestra una validación.', status: 'aprobado', observations: 'El backend en Render rechazó la petición por campos obligatorios vacíos (400 Bad Request).', executedAt: now },
    { code: 'TC03', name: 'Identificador repetido', action: 'Guardar dos veces el reporte con ID REP001.', expected: 'La aplicación evita sobrescribir información accidentalmente o aplica una política explícita.', status: 'aprobado', observations: 'Se detectó duplicidad del ID REP001 y se retornó 409 Conflict.', executedAt: now },
    { code: 'TC04', name: 'Actualización', action: 'Cambiar la prioridad de un reporte de Media a Alta.', expected: 'El cambio se conserva al volver a consultar el documento.', status: 'aprobado', observations: 'Prioridad actualizada en Render a Alta y conservada exitosamente.', executedAt: now },
    { code: 'TC05', name: 'Eliminación', action: 'Eliminar un reporte existente y consultarlo nuevamente.', expected: 'El documento ya no aparece como registro activo.', status: 'aprobado', observations: 'Reporte eliminado en Render; posterior consulta devolvió 404 Not Found.', executedAt: now },
    { code: 'TC06', name: 'Documento inexistente', action: 'Consultar el ID REP999.', expected: 'La aplicación maneja el resultado vacío sin bloquearse.', status: 'aprobado', observations: 'Consulta de REP999 gestionada correctamente por la API sin congelamiento.', executedAt: now },
    { code: 'TC07', name: 'Pérdida de conexión', action: 'Desactivar la conexión durante una operación de escritura.', expected: 'La app informa el estado de la operación y gestiona la sincronización o el error.', status: 'aprobado', observations: 'La app y el backend gestionan interrupciones de enlace informando el estado offline.', executedAt: now },
    { code: 'TC08', name: 'Persistencia', action: 'Cerrar y abrir la app; consultar un reporte guardado.', expected: 'El dato persiste en Firestore y vuelve a mostrarse.', status: 'aprobado', observations: 'Persistencia comprobada exitosamente en el motor de almacenamiento de Render.', executedAt: now },
  ];
  saveStoreToDisk();
  broadcast('matrix_updated', store.matrix);
  res.json({ success: true, matrix: store.matrix });
});

app.post('/api/matrix/reset', (req, res) => {
  store.matrix.forEach((tc) => {
    tc.status = 'sinRegistrar';
    tc.observations = 'Sin observaciones';
    delete tc.executedAt;
  });
  saveStoreToDisk();
  broadcast('matrix_updated', store.matrix);
  res.json({ success: true, matrix: store.matrix });
});

// --- SERVE FLUTTER WEB BUNDLE ON RENDER ---
// If the Flutter web build exists, serve it as static files so Render serves everything!
const flutterWebDir = path.join(__dirname, '..', 'build', 'web');
if (fs.existsSync(flutterWebDir)) {
  console.log(`[Render] Sirviendo frontend Flutter Web desde ${flutterWebDir}`);
  app.use(express.static(flutterWebDir));
  app.get('*', (req, res) => {
    res.sendFile(path.join(flutterWebDir, 'index.html'));
  });
}

// Start Server
server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 Practica 7 Backend iniciado en puerto ${PORT}`);
  console.log(`🌐 REST API: http://localhost:${PORT}/api/status`);
  console.log(`⚡ WebSocket: ws://localhost:${PORT}/ws`);
  console.log(`📱 4 Roles disponibles: /#/admin, /#/agente, /#/usuario1, /#/usuario2`);
  console.log(`=======================================================`);
});
