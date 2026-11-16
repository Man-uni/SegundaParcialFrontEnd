# API de Comandas (Parcial de Flutter)

Node.js puro, sin dependencias, datos en memoria, seguridad JWT.

```bash
node server.js     # http://localhost:4004
```

Usuario de prueba: `admin` / `123`. El token dura 1 hora.
Al reiniciar el servidor vuelven los datos iniciales (11 platos y 2 pedidos).

## Endpoints

| Método | Ruta                    | Token | Descripción |
|--------|-------------------------|-------|-------------|
| POST   | /login                  | No    | `{usuario, password}` -> `{token}` (401 si es incorrecto) |
| GET    | /platos                 | Sí    | Lista de platos. Filtro opcional `?categoria=Bebidas` |
| GET    | /pedidos                | Sí    | Lista de pedidos con sus items |
| GET    | /pedidos/:id            | Sí    | Un pedido (404 si no existe) |
| POST   | /pedidos                | Sí    | Crea pedido `{mesa, cliente, items:[{plato_id, cantidad}]}`. El servidor calcula precios y total. 201 / 400 |
| PUT    | /pedidos/:id/estado     | Sí    | `{"estado":"entregado"}`. 409 si no estaba pendiente |
| DELETE | /pedidos/:id            | Sí    | Cancela el pedido. 409 si no está pendiente |

Categorías: Entradas, Platos principales, Bebidas, Postres.
Hay platos con `disponible: false`: el POST los rechaza con 400.

## curl

```bash
TOKEN=$(curl -s -X POST http://localhost:4004/login -H "Content-Type: application/json" \
  -d '{"usuario":"admin","password":"123"}' | grep -o 'eyJ[^"]*')

curl http://localhost:4004/platos -H "Authorization: Bearer $TOKEN"
curl "http://localhost:4004/platos?categoria=Bebidas" -H "Authorization: Bearer $TOKEN"
curl http://localhost:4004/pedidos -H "Authorization: Bearer $TOKEN"

curl -X POST http://localhost:4004/pedidos -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"mesa":7,"cliente":"Ana","items":[{"plato_id":1,"cantidad":3},{"plato_id":9,"cantidad":2}]}'

curl -X PUT http://localhost:4004/pedidos/2/estado -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" -d '{"estado":"entregado"}'

curl -X DELETE http://localhost:4004/pedidos/2 -H "Authorization: Bearer $TOKEN"
```

## Desde Flutter
- Chrome / escritorio: `http://localhost:4004`
- Emulador Android: `http://10.0.2.2:4004`
- CORS habilitado (incluye `Authorization`).
