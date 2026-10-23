# Guía de Conexión y Despliegue en Render (Práctica 7)

Esta guía explica cómo conectar los **4 dispositivos remotos a través de Render.com**, permitiendo que interactúen por internet en tiempo real desde diferentes teléfonos, laptops o redes mediante **WebSockets** y **REST API**.

---

## 🏗️ 1. Arquitectura de Conexión en Render

El backend ubicado en [`server/server.js`](file:///c:/Users/josue/Practica7/server/server.js) está optimizado para la nube de Render:

```
[Dispositivo 1: Admin]      ──┐
[Dispositivo 2: Agente]     ──┼──►  RENDER.COM (WebSockets + API REST)  ◄── Servidor Central
[Dispositivo 3: Usuario 1]  ──┤     https://tu-servicio.onrender.com
[Dispositivo 4: Usuario 2]  ──┘     wss://tu-servicio.onrender.com/ws
```

### URLs Preasignadas en Render:
Una vez desplegado tu servicio en Render (ej. `https://practica7-helpdesk.onrender.com`), cada dispositivo abre su enlace correspondiente en su propio navegador o celular:

1. **Dispositivo 1 (Administrador)**: `https://tu-servicio.onrender.com/#/admin`
2. **Dispositivo 2 (Agente de Atención)**: `https://tu-servicio.onrender.com/#/agente`
3. **Dispositivo 3 (Usuario 1 - Sistemas)**: `https://tu-servicio.onrender.com/#/usuario1`
4. **Dispositivo 4 (Usuario 2 - Finanzas)**: `https://tu-servicio.onrender.com/#/usuario2`

*(El servidor Node.js sirve automáticamente el frontend Flutter Web compilado y los WebSockets en el mismo dominio).*

---

## 🚀 2. Pasos para Desplegar en Render (Plan Gratuito)

### Paso 1: Subir el proyecto a GitHub
Si aún no tienes tu repositorio en GitHub:
```powershell
cd C:\Users\josue\Practica7
git init
git add .
git commit -m "Practica 7 Flutter con backend para Render"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/practica7.git
git push -u origin main
```

### Paso 2: Crear el Web Service en Render.com
1. Inicia sesión en [https://dashboard.render.com](https://dashboard.render.com).
2. Haz clic en **"New +"** y selecciona **"Web Service"**.
3. Conecta tu repositorio de GitHub `practica7`.
4. Completa la configuración:
   - **Name**: `practica7-helpdesk` (o el nombre que elijas)
   - **Region**: `Oregon (US West)` o la más cercana
   - **Branch**: `main`
   - **Root Directory**: Deja en blanco o ingresa `server`
   - **Runtime**: `Node`
   - **Build Command**:
     ```bash
     cd server && npm install
     ```
   - **Start Command**:
     ```bash
     cd server && node server.js
     ```
   - **Instance Type**: `Free`
5. En **Advanced**:
   - **Health Check Path**: `/api/status`
6. Haz clic en **"Create Web Service"**.

Render compilará el backend e iniciará el servicio en ~2 minutos, otorgándote una URL pública segura como:
👉 `https://practica7-helpdesk.onrender.com`

---

## 📱 3. Conexión de los 4 Dispositivos a Render

### Opción 1: Abrir directamente la URL de Render (La más sencilla)
Cada uno de los 4 participantes o dispositivos ingresa a la URL que te asignó Render:
- Persona 1 (Admin): `https://practica7-helpdesk.onrender.com/#/admin`
- Persona 2 (Agente): `https://practica7-helpdesk.onrender.com/#/agente`
- Persona 3 (Usuario 1): `https://practica7-helpdesk.onrender.com/#/usuario1`
- Persona 4 (Usuario 2): `https://practica7-helpdesk.onrender.com/#/usuario2`

Al cargar, el indicador en la barra superior mostrará:
🟢 **Render: Conectado**

### Opción 2: Conectar la App Móvil o de Escritorio a Render
Si un dispositivo ejecuta la aplicación en Windows o emulador móvil:
1. En la barra superior, pulsa el botón **"Render: Configurar"**.
2. Escribe la URL de tu backend en Render:
   `https://practica7-helpdesk.onrender.com`
3. Pulsa **"Guardar y Reconectar"**.
4. ¡El dispositivo se sincronizará automáticamente con los demás a través de internet!

---

## 🧪 4. Verificación de Funcionamiento en Render

1. **Prueba de Mensajería**:
   - Usuario 1 envía un mensaje desde su celular o laptop.
   - El Administrador y el Agente lo reciben instantáneamente en sus pantallas mediante WebSockets.
2. **Prueba de Desconexión del Agente**:
   - En el Dispositivo 2 (Agente), pulsa **"Desconectar Agente"**.
   - Inmediatamente en el Dispositivo 1 (Admin) aparece la alerta:
     `ALERTA: El Agente de Atención se ha DESCONECTADO. Los casos son reasignados al Administrador.`
   - Los casos asignados al Agente cambian en tiempo real a `Escalado al Administrador`.
3. **Prueba de Matriz TC01 a TC08**:
   - El Administrador ingresa a la pestaña **"Matriz de Pruebas (TC01-TC08)"**.
   - Pulsa **"Ejecutar Toda la Matriz"**.
   - Los casos se validan contra la persistencia y la API de Render en tiempo real.

---

## 💻 5. Probar el Servidor Render Localmente (Antes de Subir)

Para verificar el comportamiento exactamente igual a Render en tu computadora:

```powershell
cd C:\Users\josue\Practica7\server
npm start
```
Salida esperada en consola:
```
=======================================================
🚀 Practica 7 Backend iniciado en puerto 3000
🌐 REST API: http://localhost:3000/api/status
⚡ WebSocket: ws://localhost:3000/ws
📱 4 Roles disponibles: /#/admin, /#/agente, /#/usuario1, /#/usuario2
=======================================================
```

Luego abre en tu navegador `http://localhost:3000` y prueba los 4 roles.
