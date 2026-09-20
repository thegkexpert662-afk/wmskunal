# Kopersay WMS Backend

Node.js + Express + PostgreSQL REST API foundation for the Kopersay WMS.

## Current foundation

- Express API
- PostgreSQL connection pool
- Environment-based configuration
- Helmet security headers
- CORS configuration
- API rate limiting
- JWT access-token middleware
- Argon2 password verification
- Multi-company data model
- Company/module configuration
- Device approval data model
- GRN -> Putaway -> Inventory -> Order -> Picking -> Dispatch data model
- Returns and Invoice data model
- Audit log data model
- PostgreSQL indexes for common company-scoped queries

## Local setup

1. Install Node.js 20+.
2. Create PostgreSQL database: kopersay_wms.
3. Copy .env.example to .env and set real values.
4. Run npm install inside backend.
5. Run npm run migrate.
6. Run npm run dev.

Health check: GET /api/health

## Security notes

- Never commit .env.
- JWT_SECRET must be a long random production secret.
- PostgreSQL should not be exposed directly to the public internet.
- Business APIs must enforce company/tenant authorization on the server.
- Frontend visibility is not a security boundary.
- Device approval/WebAuthn enforcement will be completed before production authentication is enabled.
