# Zerion Integration — Execution Layer Design

## Overview

IntentGuard uses Zerion CLI as the **onchain execution engine**.

Zerion is not responsible for:
- decision making
- intent interpretation
- trigger monitoring

Instead, Zerion is used for:
- wallet operations
- transaction construction
- swap and bridge execution
- route optimization via Zerion API

---

## Integration Philosophy

We treat Zerion CLI as a:

> **deterministic, programmable transaction executor**

All intelligence (AI, policies, triggers) exists **outside** Zerion.

This ensures:
- separation of concerns
- predictable execution
- easier debugging and auditing

---

## High-Level Flow

```txt
User Intent
→ AI Council
→ Policy Generation
→ Policy Storage
→ Trigger Monitoring (external system)
→ Zerion CLI Invocation
→ Onchain Transaction
→ Result Logging
``` id="zerflow01"

---

## Core Responsibilities of Zerion CLI

### 1. Wallet Management

Zerion CLI is used to:

- create or import wallets
- manage private keys securely (via CLI environment)
- sign transactions

---

### 2. Transaction Execution

Zerion CLI handles:

- token swaps
- cross-chain bridges
- asset transfers

All execution commands are triggered programmatically from the backend.

---

### 3. Route Optimization

Zerion API provides:

- multiple swap/bridge routes
- estimated outputs
- gas estimates
- slippage bounds

IntentGuard selects routes based on:
- policy constraints
- best available outcome (e.g. max output)

---

### 4. Policy Enforcement (Partial)

Zerion CLI may support:

- agent tokens
- execution policies (e.g. allowed chains, expiry)

These are treated as:
- **secondary safety layer**

Primary enforcement happens in our Policy Engine.

---

## What Zerion Does NOT Do (Important)

Zerion CLI does NOT:

- monitor price conditions continuously
- trigger transactions automatically over time
- interpret user intent
- run AI agents

These responsibilities are handled by:

- Trigger Worker (backend service)
- Policy Engine
- AI Council

---

## Invocation Model

Zerion CLI is invoked by our backend as a subprocess or command execution.

Example flow:

```txt id="zerflow02"
Trigger condition met
→ Backend validates policy
→ Backend requests route data (Zerion API)
→ Backend selects optimal route
→ Backend calls Zerion CLI command
→ Zerion signs and broadcasts transaction

Execution Strategy
Step 1: Fetch Route
Query Zerion API for swap/bridge offers
Filter based on:
allowed chains
slippage limits
token constraints
Step 2: Validate Against Policy

Before execution:

ensure route complies with all constraints
reject if:
chain not allowed
slippage too high
contract not trusted
Step 3: Execute via CLI
call Zerion CLI command
pass required parameters
sign transaction
broadcast to network
Step 4: Capture Result
transaction hash
execution status
route used
gas used (if available)
Safety Model

We enforce safety in two layers:

Layer 1 — Internal Policy Engine (Primary)
strict validation before execution
full control over constraints
Layer 2 — Zerion CLI Policies (Secondary, Optional)

If available:

agent tokens with restrictions
additional execution constraints
Flexibility & Unknowns

This integration is intentionally not rigid.

Areas to be refined during implementation:

exact CLI command structure
agent token capabilities
policy enforcement depth within Zerion
route filtering APIs and parameters

The system should:

adapt to Zerion’s real capabilities
avoid assumptions that limit execution
Future Enhancements
deeper use of Zerion policy system (if mature)
streaming or event-based triggers (if supported)
tighter integration with Zerion API responses
batching or multi-step execution flows
Summary

Zerion CLI is used as:

the execution engine
the route provider
the transaction signer

IntentGuard builds around it:

AI defines intent
policies enforce safety
backend triggers execution
Zerion performs the transaction

This separation ensures:

reliability
flexibility
and safe automation