# API de Ventas — con seguridad JWT

Backend en **Node.js puro** (sin dependencias, sin base de datos). El
JWT se genera y valida a mano con el módulo `crypto` que ya viene
incluido en Node — no hace falta instalar nada.

## Cómo correrlo

```bash
node server.js
```

⚠️ Los datos viven en memoria: si reiniciás el servidor, vuelve a las 2
ventas iniciales.

## Usuario de prueba (hardcodeado)

```
usuario:  admin
password: 123
```

## Endpoints

| Método | Ruta      | Requiere token | Descripción                                    |
|--------|-----------|-----------------|-------------------------------------------------|
| POST   | `/login`  | No              | Devuelve un token JWT si el usuario/password son correctos |
| GET    | `/ventas` | **Sí**          | Lista todas las ventas, con sus detalles         |
| POST   | `/ventas` | **Sí**          | Crea una nueva venta con sus detalles            |

El token dura **1 hora**. Pasado ese tiempo, hay que pedir uno nuevo con `/login`.

## Probarlo con curl

**1) Obtener el token:**

```bash
curl -X POST http://localhost:4002/login \
  -H "Content-Type: application/json" \
  -d '{"usuario":"admin","password":"123"}'
```

Respuesta:

```json
{ "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....." }
```

**2) Usar el token para consumir /ventas:**

```bash
curl http://localhost:4002/ventas \
  -H "Authorization: Bearer PEGAR_EL_TOKEN_AQUI"
```

**3) Sin token (para comprobar que da 401):**

```bash
curl -i http://localhost:4002/ventas
```

**4) Crear una venta (también requiere el token):**

```bash
curl -X POST http://localhost:4002/ventas \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer PEGAR_EL_TOKEN_AQUI" \
  -d '{
    "fecha": "07/09/2026",
    "cliente": "Maria Lopez",
    "total": 34000,
    "detalles": [
      { "cantidad": 1, "descripcion": "Remera", "precio_unitario": 25000, "total_detalle": 25000 },
      { "cantidad": 3, "descripcion": "Medias", "precio_unitario": 3000, "total_detalle": 9000 }
    ]
  }'
```

## CORS

El servidor ya responde con los headers necesarios (incluido
`Authorization`) para que el proyecto Next.js (`http://localhost:3000`)
lo pueda consumir sin configuración adicional.

## Nota de seguridad

Esto es una simplificación **solo para la práctica**: el usuario está
hardcodeado y el secreto para firmar el JWT está en el código. En un
proyecto real, el secreto va en una variable de entorno y los usuarios
se validan contra una base de datos con contraseñas hasheadas.
