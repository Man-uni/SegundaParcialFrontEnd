/**
 * API de Ventas - Backend para el Primer Parcial (con seguridad JWT)
 * Facultad Politecnica - UNA / Programacion Web Frontend
 *
 * Node.js puro, sin dependencias externas (el JWT se genera a mano con
 * el modulo "crypto" que ya viene incluido en Node). Datos en memoria
 * (se pierden al reiniciar el servidor). Corre con: node server.js
 *
 * Entidad Venta:
 *   { id, fecha, cliente, total, detalles: [ { cantidad, descripcion, precio_unitario, total_detalle } ] }
 *
 * Endpoints:
 *   POST /login    -> devuelve un token JWT si el usuario y password son correctos
 *   GET  /ventas   -> lista todas las ventas, con sus detalles   (requiere Bearer token)
 *   POST /ventas   -> crea una nueva venta con sus detalles      (requiere Bearer token)
 *
 * Usuario de prueba (hardcodeado, solo para la practica):
 *   usuario: admin
 *   password: 123
 */

const http = require("http");
const crypto = require("crypto");

const PORT = 4002;

// ---- Usuario hardcodeado y secreto para firmar el JWT ----
const USUARIO_VALIDO = "admin";
const PASSWORD_VALIDA = "123";
const SECRETO_JWT = "clave-secreta-solo-para-la-practica"; // en un proyecto real, esto va en una variable de entorno
const EXPIRACION_SEGUNDOS = 60 * 60; // el token dura 1 hora

// ---- JWT hecho a mano con HMAC-SHA256 (sin librerias externas) ----
function base64url(texto) {
  return Buffer.from(texto).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function base64urlDecode(str) {
  str = str.replace(/-/g, "+").replace(/_/g, "/");
  while (str.length % 4) str += "=";
  return Buffer.from(str, "base64").toString();
}

function firmar(headerB64, payloadB64) {
  return crypto
    .createHmac("sha256", SECRETO_JWT)
    .update(`${headerB64}.${payloadB64}`)
    .digest("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function crearToken(payload) {
  const header = { alg: "HS256", typ: "JWT" };
  const ahora = Math.floor(Date.now() / 1000);
  const payloadCompleto = { ...payload, iat: ahora, exp: ahora + EXPIRACION_SEGUNDOS };
  const headerB64 = base64url(JSON.stringify(header));
  const payloadB64 = base64url(JSON.stringify(payloadCompleto));
  const firma = firmar(headerB64, payloadB64);
  return `${headerB64}.${payloadB64}.${firma}`;
}

function verificarToken(token) {
  const partes = token.split(".");
  if (partes.length !== 3) return null;
  const [headerB64, payloadB64, firma] = partes;
  if (firmar(headerB64, payloadB64) !== firma) return null; // token alterado o mal firmado
  let payload;
  try {
    payload = JSON.parse(base64urlDecode(payloadB64));
  } catch {
    return null;
  }
  const ahora = Math.floor(Date.now() / 1000);
  if (payload.exp && ahora > payload.exp) return null; // token vencido
  return payload;
}

// Extrae y valida el token del header Authorization: Bearer <token>
function obtenerUsuarioDesdeRequest(req) {
  const auth = req.headers["authorization"] || "";
  const [tipo, token] = auth.split(" ");
  if (tipo !== "Bearer" || !token) return null;
  return verificarToken(token);
}

// ---- "Base de datos" en memoria ----
let ventas = [
  {
    id: 1,
    fecha: "10/08/2026",
    cliente: "Juan Perez",
    total: 59000,
    detalles: [
      { cantidad: 2, descripcion: "Zapato", precio_unitario: 22000, total_detalle: 44000 },
      { cantidad: 3, descripcion: "Media", precio_unitario: 5000, total_detalle: 15000 },
    ],
  },
  {
    id: 2,
    fecha: "01/09/2026",
    cliente: "Diego Gonzalez",
    total: 120000,
    detalles: [
      { cantidad: 1, descripcion: "Campera", precio_unitario: 90000, total_detalle: 90000 },
      { cantidad: 2, descripcion: "Gorra", precio_unitario: 15000, total_detalle: 30000 },
    ],
  },
];
let proximoId = 3;

// ---- Helpers ----
function enviarJSON(res, statusCode, data) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
  });
  res.end(JSON.stringify(data, null, 2));
}

function leerBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch (err) {
        reject(err);
      }
    });
  });
}

function validarVenta(v) {
  const errores = [];
  if (!v.fecha) errores.push("fecha");
  if (!v.cliente) errores.push("cliente");
  if (v.total === undefined || v.total === null || v.total === "") errores.push("total");
  if (!Array.isArray(v.detalles) || v.detalles.length === 0) {
    errores.push("detalles (debe ser un arreglo con al menos un elemento)");
  } else {
    v.detalles.forEach((d, i) => {
      const campos = ["cantidad", "descripcion", "precio_unitario", "total_detalle"];
      campos.forEach((c) => {
        if (d[c] === undefined || d[c] === null || d[c] === "") {
          errores.push(`detalles[${i}].${c}`);
        }
      });
    });
  }
  return errores;
}

// ---- Servidor ----
const server = http.createServer(async (req, res) => {
  const pathname = req.url.split("?")[0];
  const metodo = req.method;

  console.log(`${new Date().toLocaleTimeString()}  ${metodo}  ${pathname}`);

  if (metodo === "OPTIONS") {
    res.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    });
    return res.end();
  }

  // POST /login
  if (pathname === "/login" && metodo === "POST") {
    let credenciales;
    try {
      credenciales = await leerBody(req);
    } catch {
      return enviarJSON(res, 400, { error: "El JSON enviado no es valido" });
    }

    if (credenciales.usuario === USUARIO_VALIDO && credenciales.password === PASSWORD_VALIDA) {
      const token = crearToken({ usuario: credenciales.usuario });
      return enviarJSON(res, 200, { token });
    }
    return enviarJSON(res, 401, { error: "Usuario o password incorrectos" });
  }

  // A partir de aqui, /ventas (GET y POST) requieren token valido
  if (pathname === "/ventas") {
    const usuario = obtenerUsuarioDesdeRequest(req);
    if (!usuario) {
      return enviarJSON(res, 401, { error: "Token faltante o invalido. Obtenelo en POST /login." });
    }
  }

  // GET /ventas
  if (pathname === "/ventas" && metodo === "GET") {
    return enviarJSON(res, 200, ventas);
  }

  // POST /ventas
  if (pathname === "/ventas" && metodo === "POST") {
    let nueva;
    try {
      nueva = await leerBody(req);
    } catch {
      return enviarJSON(res, 400, { error: "El JSON enviado no es valido" });
    }

    const errores = validarVenta(nueva);
    if (errores.length > 0) {
      return enviarJSON(res, 400, { error: `Faltan o son invalidos los siguientes campos: ${errores.join(", ")}` });
    }

    const venta = {
      id: proximoId++,
      fecha: String(nueva.fecha),
      cliente: String(nueva.cliente),
      total: Number(nueva.total),
      detalles: nueva.detalles.map((d) => ({
        cantidad: Number(d.cantidad),
        descripcion: String(d.descripcion),
        precio_unitario: Number(d.precio_unitario),
        total_detalle: Number(d.total_detalle),
      })),
    };
    ventas.push(venta);
    return enviarJSON(res, 201, venta);
  }

  if (pathname === "/" && metodo === "GET") {
    return enviarJSON(res, 200, {
      mensaje: "API de Ventas - Facultad Politecnica UNA",
      endpoints: ["POST /login", "GET  /ventas  (requiere Bearer token)", "POST /ventas  (requiere Bearer token)"],
    });
  }

  enviarJSON(res, 404, { error: "Ruta no encontrada" });
});

server.listen(PORT, () => {
  console.log("=================================================");
  console.log(`  API de Ventas corriendo en http://localhost:${PORT}`);
  console.log("  POST /login   (usuario: admin, password: 123)");
  console.log("  GET/POST /ventas ahora requieren: Authorization: Bearer <token>");
  console.log("  Ctrl + C para detenerla");
  console.log("=================================================");
});
