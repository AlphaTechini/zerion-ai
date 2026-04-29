# IntentGuard — Policy-Driven Autonomous Onchain Execution (Built on Zerion CLI)

## The Problem

Onchain automation is broken in a very specific way:

- Users either trade manually → slow, emotional, inefficient  
- Or use “AI trading bots” → opaque, risky, and untrustworthy  

Most existing solutions:
- act too fast without constraints  
- or require constant user monitoring  
- or expose users to unsafe contracts and routes  

There is no system that allows users to:

> define *what they want*  
> enforce *how it should be done safely*  
> and let execution happen *automatically onchain*  

without giving up control.

---

## What We Built

**IntentGuard** is a policy-driven autonomous execution system.

Users define a high-level intent.  
AI converts that intent into structured, constrained policies.  
The system monitors conditions and executes real onchain transactions using Zerion CLI.

---

## Core Idea

> AI decides the strategy  
> Policies enforce the rules  
> Zerion CLI executes the transaction  

---

## Why This Works

### 1. Separation of Concerns

We split the system into:

- **AI Layer** → defines *what to do*  
- **Policy Layer** → defines *what is allowed*  
- **Execution Layer** → performs *deterministic onchain actions*  

This avoids:
- slow AI decision loops  
- unsafe “god-mode” agents  
- unpredictable execution  

---

### 2. Deterministic Execution

Once a policy is created:
- no AI is involved in real-time execution  
- triggers are evaluated instantly  
- actions are executed reliably  

This makes the system:
- fast  
- predictable  
- auditable  

---

### 3. Built-in Safety

Every action is constrained by:

- chain restrictions  
- spend limits  
- slippage limits  
- contract allowlists  
- expiry windows  

Unsafe actions are blocked before execution.

---

### 4. Real Onchain Transactions

Using Zerion CLI:

- swaps, bridges, and transfers are executed onchain  
- optimal routes are fetched via Zerion API  
- transactions are signed and broadcasted  

No simulations. Real execution.

---

## Why Zerion CLI

:contentReference[oaicite:0]{index=0} provides:

- multi-chain wallet infrastructure (EVM + Solana)  
- swap and bridge execution  
- portfolio and transaction data  
- routing via aggregators (1inch, 0x, etc.)  

It acts as the **execution engine**, allowing us to focus on:
- policy design  
- automation logic  
- user experience  

---

## Key Features

### Intent-Based Execution
Users express goals in plain language:
- “Buy ETH if price drops 5%”
- “Convert USDC to ETH using the best route”

---

### AI Policy Council
Multiple agents analyze intent:
- Strategy Agent → defines approach  
- Risk Agent → limits exposure  
- Security Agent → enforces safety  

---

### Policy Engine
Generates enforceable rules:
- triggers (price, time, state)
- constraints (chain, slippage, spend)
- expiry conditions

---

### Autonomous Execution
A trigger worker:
- monitors conditions  
- fetches optimal routes  
- executes via Zerion CLI  

---

### Transparent Logs
Every action is recorded:
- why it was triggered  
- what route was chosen  
- what was executed or blocked  

---

### Rejection System
Unsafe actions are blocked and logged:

Example:

Proposed route: Ethereum Mainnet
Blocked: Chain not allowed


---

## Example Flow

1. User defines intent:
   > “Buy ETH if price drops 5%”

2. AI Council generates policy:
   - Max spend: 100 USDC  
   - Chain: Base  
   - Slippage: 1.5%  
   - Expiry: 24h  

3. System monitors conditions  

4. Condition is met  

5. Zerion CLI executes swap  

6. Transaction is logged and displayed  

---

## System Architecture


Frontend (Web / CLI)
↓
Intent API
↓
AI Council
↓
Policy Engine
↓
Policy Store
↓
Trigger Worker
↓
Zerion CLI
↓
Onchain Transaction
↓
Logs & Dashboard


---

## Design Principles

- Control over automation  
- Safety before execution  
- Transparency over black-box AI  
- Deterministic systems over probabilistic behavior  
- Real usage over demo gimmicks  

---

## What Makes This Different

Most projects:
- use AI to execute trades directly  
- rely on opaque decision-making  
- ignore safety constraints  

IntentGuard:
- uses AI only for planning  
- enforces strict execution policies  
- separates decision from execution  
- provides full visibility into every action  

---

## Future Improvements

- richer trigger conditions (volatility, onchain signals)  
- multi-agent voting systems  
- user-defined custom policies  
- protocol risk scoring  
- advanced anomaly detection  

---

## Conclusion

IntentGuard redefines onchain automation:

Instead of trusting AI to act freely,  
we let users define intent,  
AI structure it,  
and policies enforce it.

Execution becomes:
- safe  
- automatic  
- predictable  

Built on Zerion CLI, this system turns wallets into programmable, policy-driven agents.

---