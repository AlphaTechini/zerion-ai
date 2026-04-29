# Database Layer

This directory contains IntentGuard database definitions that sit beside the upstream Zerion CLI code.

## Architectural Decisions

The database is the control and audit plane for IntentGuard. Zerion CLI and OWS remain responsible for wallet custody, signing, agent tokens, and real transaction execution.

The schema uses Drizzle with PostgreSQL because financial automation needs traceable relational data, while JSONB remains useful for AI-generated policy payloads and raw Zerion route snapshots.

Secrets do not belong in this layer. Private keys, seed phrases, passphrases, API keys, and raw agent-token values must stay in OWS, environment-managed runtime configuration, or another secure secret store.

## Files

To find the schema entry point visit [schema/index.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/index.ts).

To find the schema design document visit [Schema.md](file:///C:/Hackathons/Zerion%20CLI/docs/intentguard/Schema.md).

The Drizzle configuration can be found in [drizzle.config.ts](file:///C:/Hackathons/Zerion%20CLI/drizzle.config.ts).

## Tradeoffs

The schema is split into small modules instead of one monolithic file. This adds a few imports, but it keeps wallet identity, policies, executions, and settings independently reviewable.
