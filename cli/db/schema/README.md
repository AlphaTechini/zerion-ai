# Drizzle Schema

This directory contains the Drizzle table definitions for IntentGuard.

## Architectural Decisions

The schema mirrors Zerion's real execution model. A logical wallet can have multiple chain accounts, IntentGuard policies are separate from Zerion/OWS policies, and approvals are tracked separately from swaps because approvals are security-sensitive.

## Files

To find shared enum definitions visit [enums.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/enums.ts).

To find user and wallet tables visit [identity.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/identity.ts).

To find intent, policy, and AI review tables visit [policies.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/policies.ts).

To find trigger, route, execution, approval, and log tables visit [executions.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/executions.ts).

To find user default risk settings visit [settings.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/settings.ts).

The schema entry point can be found in [index.ts](file:///C:/Hackathons/Zerion%20CLI/cli/db/schema/index.ts).

## Tradeoffs

The modules use PostgreSQL enums for constrained lifecycle fields. This gives stronger database validation than plain text checks, but enum changes require intentional migrations.
