# Web API CORS requirements

The Flutter Web app calls the existing API directly at
`https://api.tuhfatulmuslim.com/api/v1`; it does not use a proxy or a second
API. Because requests send `Content-Type: application/json`, `X-API-Key`,
`Accept-Language`, and (after sign-in) `Authorization`, browsers send an
`OPTIONS` preflight before the request.

The API must allow the following exact origins in production and development:

- `http://localhost:<the Flutter Web port>` (for local development; use an
  explicit port such as `7357` for a stable allowlist)
- the final HTTPS Web deployment origin, for example
  `https://app.tuhfatulmuslim.com`

Do not use `*` together with credentials. The CORS middleware must run before
authentication, API-key validation, and route handlers, and must answer
`OPTIONS` with `204` or `200`.

Required policy:

```text
Access-Control-Allow-Origin: <validated request Origin>
Vary: Origin
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept, Accept-Language, Authorization, X-API-Key
Access-Control-Expose-Headers: Authorization, X-Access-Token
Access-Control-Allow-Credentials: true   # only if the backend actually uses cookies
```

For an Express backend, apply the equivalent of this **before** routes:

```ts
const allowedOrigins = new Set([
  'http://localhost:7357',
  'https://app.tuhfatulmuslim.com',
]);

const corsOptions = {
  origin(origin, callback) {
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type', 'Accept', 'Accept-Language', 'Authorization', 'X-API-Key',
  ],
  exposedHeaders: ['Authorization', 'X-Access-Token'],
  credentials: true,
  maxAge: 86400,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
```

Verified on 2026-11-10: the API itself returns `200` without an Origin header,
but responds `500 {"message":"Not allowed by CORS"}` to both an OPTIONS
preflight and an Origin-bearing GET from `http://localhost:7357`. This server
configuration must be corrected before browser login or API data can work.
