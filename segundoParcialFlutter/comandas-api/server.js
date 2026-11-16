/**
 * API de Comandas (restaurante) - Primer Parcial de Flutter
 * Facultad Politecnica - UNA
 *
 * Node.js puro, sin dependencias. Datos en memoria. Corre con: node server.js
 * Seguridad: JWT (Bearer). Usuario de prueba: admin / 123
 *
 * Endpoints:
 *   POST   /login              -> { token }                       (publico)
 *   GET    /platos             -> lista de platos (?categoria=X)  (token)
 *   GET    /pedidos            -> lista de pedidos                (token)
 *   GET    /pedidos/:id        -> un pedido                       (token)
 *   POST   /pedidos            -> crea un pedido                  (token)
 *   PUT    /pedidos/:id/estado -> marca como "entregado"          (token)
 *   DELETE /pedidos/:id        -> cancela (borra) un pedido       (token)
 */
const http = require("http");
const crypto = require("crypto");

const PORT = 4004;
const USUARIO = "admin", PASSWORD = "123";
const SECRETO = "clave-secreta-solo-para-la-practica";
const EXPIRA = 60 * 60;

// ---------- JWT a mano ----------
const b64 = (s) => Buffer.from(s).toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
const unb64 = (s) => { s = s.replace(/-/g, "+").replace(/_/g, "/"); while (s.length % 4) s += "="; return Buffer.from(s, "base64").toString(); };
const firmar = (h, p) => crypto.createHmac("sha256", SECRETO).update(`${h}.${p}`).digest("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
function crearToken(payload) {
  const ahora = Math.floor(Date.now() / 1000);
  const h = b64(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const p = b64(JSON.stringify({ ...payload, iat: ahora, exp: ahora + EXPIRA }));
  return `${h}.${p}.${firmar(h, p)}`;
}
function verificar(token) {
  const x = token.split(".");
  if (x.length !== 3 || firmar(x[0], x[1]) !== x[2]) return null;
  try { const p = JSON.parse(unb64(x[1])); return p.exp > Math.floor(Date.now() / 1000) ? p : null; } catch { return null; }
}

// ---------- Datos en memoria ----------
const platos = [
  { id: 1, nombre: "Empanada de carne", categoria: "Entradas", precio: 8000, disponible: true },
  { id: 2, nombre: "Sopa paraguaya", categoria: "Entradas", precio: 12000, disponible: true },
  { id: 3, nombre: "Provoleta", categoria: "Entradas", precio: 25000, disponible: false },
  { id: 4, nombre: "Milanesa con fritas", categoria: "Platos principales", precio: 45000, disponible: true },
  { id: 5, nombre: "Bife de chorizo", categoria: "Platos principales", precio: 75000, disponible: true },
  { id: 6, nombre: "Pastel mandi'o", categoria: "Platos principales", precio: 38000, disponible: true },
  { id: 7, nombre: "Gaseosa", categoria: "Bebidas", precio: 10000, disponible: true },
  { id: 8, nombre: "Jugo de naranja", categoria: "Bebidas", precio: 15000, disponible: true },
  { id: 9, nombre: "Cerveza", categoria: "Bebidas", precio: 20000, disponible: true },
  { id: 10, nombre: "Flan casero", categoria: "Postres", precio: 18000, disponible: true },
  { id: 11, nombre: "Helado (2 bochas)", categoria: "Postres", precio: 16000, disponible: false },
];
let pedidos = [
  { id: 1, fecha: "2026-10-31T12:10:00", mesa: 3, cliente: "Juan Perez", estado: "entregado",
    items: [{ plato_id: 4, nombre: "Milanesa con fritas", precio: 45000, cantidad: 2, subtotal: 90000 }, { plato_id: 7, nombre: "Gaseosa", precio: 10000, cantidad: 2, subtotal: 20000 }], total: 110000 },
  { id: 2, fecha: "2026-10-31T12:40:00", mesa: 5, cliente: "Maria Lopez", estado: "pendiente",
    items: [{ plato_id: 5, nombre: "Bife de chorizo", precio: 75000, cantidad: 1, subtotal: 75000 }], total: 75000 },
];
let proximoId = 3;

// ---------- Utilidades ----------
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};
function enviar(res, status, data) {
  res.writeHead(status, { "Content-Type": "application/json; charset=utf-8", ...CORS });
  res.end(JSON.stringify(data, null, 2));
}
function leerBody(req) {
  return new Promise((ok, fail) => {
    let b = ""; req.on("data", (c) => (b += c));
    req.on("end", () => { if (!b) return ok({}); try { ok(JSON.parse(b)); } catch (e) { fail(e); } });
  });
}
const entero = (v) => Number.isInteger(v) && v > 0;

function armarPedido(b) {
  const errores = [];
  if (!entero(b.mesa)) errores.push("mesa (entero > 0)");
  if (typeof b.cliente !== "string" || !b.cliente.trim()) errores.push("cliente (texto)");
  if (!Array.isArray(b.items) || b.items.length === 0) return { error: "items debe ser un arreglo con al menos un elemento" };
  const items = [];
  for (const [i, it] of b.items.entries()) {
    if (!entero(it.plato_id) || !entero(it.cantidad)) { errores.push(`items[${i}] (plato_id y cantidad enteros > 0)`); continue; }
    const pl = platos.find((p) => p.id === it.plato_id);
    if (!pl) { errores.push(`items[${i}]: el plato ${it.plato_id} no existe`); continue; }
    if (!pl.disponible) { errores.push(`items[${i}]: "${pl.nombre}" no esta disponible`); continue; }
    items.push({ plato_id: pl.id, nombre: pl.nombre, precio: pl.precio, cantidad: it.cantidad, subtotal: pl.precio * it.cantidad });
  }
  if (errores.length) return { error: "Datos invalidos: " + errores.join("; ") };
  return { items, total: items.reduce((s, x) => s + x.subtotal, 0) };
}

// ---------- Servidor ----------
http.createServer(async (req, res) => {
  const ruta = req.url.split("?")[0], query = new URLSearchParams(req.url.split("?")[1] || "");
  const partes = ruta.split("/").filter(Boolean);
  console.log(`${new Date().toLocaleTimeString()}  ${req.method}  ${req.url}`);

  if (req.method === "OPTIONS") { res.writeHead(204, CORS); return res.end(); }

  if (req.method === "POST" && ruta === "/login") {
    let b; try { b = await leerBody(req); } catch { return enviar(res, 400, { error: "JSON invalido" }); }
    if (b.usuario === USUARIO && b.password === PASSWORD) return enviar(res, 200, { token: crearToken({ usuario: USUARIO }) });
    return enviar(res, 401, { error: "Usuario o password incorrectos" });
  }
  if (ruta === "/") return enviar(res, 200, { mensaje: "API de Comandas - Facultad Politecnica UNA", endpoints: ["POST /login", "GET /platos", "GET /pedidos", "GET /pedidos/:id", "POST /pedidos", "PUT /pedidos/:id/estado", "DELETE /pedidos/:id"] });

  // ---- a partir de aca todo requiere token ----
  const auth = req.headers["authorization"] || "";
  if (!auth.startsWith("Bearer ") || !verificar(auth.slice(7))) return enviar(res, 401, { error: "Token faltante, invalido o vencido. Obtenelo en POST /login." });

  if (req.method === "GET" && ruta === "/platos") {
    const cat = query.get("categoria");
    return enviar(res, 200, cat ? platos.filter((p) => p.categoria === cat) : platos);
  }
  if (partes[0] === "pedidos") {
    const id = partes[1] !== undefined ? Number(partes[1]) : null;
    if (id === null) {
      if (req.method === "GET") return enviar(res, 200, pedidos);
      if (req.method === "POST") {
        let b; try { b = await leerBody(req); } catch { return enviar(res, 400, { error: "JSON invalido" }); }
        const r = armarPedido(b);
        if (r.error) return enviar(res, 400, { error: r.error });
        const nuevo = { id: proximoId++, fecha: new Date().toISOString().slice(0, 19), mesa: b.mesa, cliente: b.cliente.trim(), estado: "pendiente", items: r.items, total: r.total };
        pedidos.push(nuevo);
        return enviar(res, 201, nuevo);
      }
    } else {
      const ped = pedidos.find((p) => p.id === id);
      if (!ped) return enviar(res, 404, { error: "Pedido no encontrado" });
      if (req.method === "GET" && partes.length === 2) return enviar(res, 200, ped);
      if (req.method === "PUT" && partes[2] === "estado") {
        let b; try { b = await leerBody(req); } catch { return enviar(res, 400, { error: "JSON invalido" }); }
        if (b.estado !== "entregado") return enviar(res, 400, { error: 'estado debe ser "entregado"' });
        if (ped.estado !== "pendiente") return enviar(res, 409, { error: "Solo se puede entregar un pedido pendiente" });
        ped.estado = "entregado";
        return enviar(res, 200, ped);
      }
      if (req.method === "DELETE" && partes.length === 2) {
        if (ped.estado !== "pendiente") return enviar(res, 409, { error: "Solo se puede cancelar un pedido pendiente" });
        pedidos = pedidos.filter((p) => p.id !== id);
        return enviar(res, 200, ped);
      }
    }
  }
  enviar(res, 404, { error: "Ruta no encontrada" });
}).listen(PORT, () => {
  console.log("=================================================");
  console.log(`  API de Comandas corriendo en http://localhost:${PORT}`);
  console.log("  Usuario: admin / Password: 123  (POST /login)");
  console.log("  Ctrl + C para detenerla");
  console.log("=================================================");
});
