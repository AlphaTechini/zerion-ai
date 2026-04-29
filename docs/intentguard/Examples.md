# Examples — Core Use Cases for IntentGuard

## Overview

IntentGuard is not a general-purpose AI trading system.

It focuses on **structured, policy-driven onchain execution**, where:
- users define intent
- AI converts it into safe policies
- execution happens automatically via Zerion CLI

Below are the primary use cases the system is designed for.

---

## 1. Conditional Accumulation (Buy the Dip, Safely)

### Intent
"Buy ETH if price drops by 5% within 24 hours"

### What Happens
- AI defines execution strategy (swap USDC → ETH)
- Policy enforces:
  - max spend (e.g. 100 USDC)
  - allowed chain (e.g. Base)
  - slippage limit (e.g. 1.5%)

### Execution
- System monitors price
- When condition is met:
  - best route is fetched via Zerion
  - swap is executed automatically

### Why This Matters
- removes emotional trading
- avoids constant monitoring
- ensures safe execution boundaries

---

## 2. Optimal Route Conversion (Smart Swaps & Bridges)

### Intent
"Convert 500 USDC to ETH using the best route within 12 hours"

### What Happens
- AI determines:
  - whether to swap directly or bridge first
- Policy enforces:
  - allowed chains (e.g. Base, Arbitrum)
  - max slippage
  - expiry window

### Execution
- System periodically checks Zerion route offers
- When optimal conditions are met:
  - executes best available swap/bridge path

### Why This Matters
- users don’t need to manually compare routes
- avoids inefficient or expensive swaps
- leverages Zerion’s routing engine automatically

---

## 3. Portfolio Rebalancing (Maintain Target Allocation)

### Intent
"Keep ETH at 40% of my portfolio"

### What Happens
- AI defines rebalance thresholds
- Policy enforces:
  - max trade size per rebalance
  - allowed assets and chains
  - cooldown between actions

### Execution
- System monitors portfolio allocation
- When deviation exceeds threshold:
  - executes partial swaps to rebalance

### Why This Matters
- passive portfolio management
- avoids overexposure to volatility
- reduces manual adjustments

---

## 4. Safe Exit Strategy (Risk-Off Automation)

### Intent
"If ETH drops 10%, convert all ETH to USDC"

### What Happens
- AI defines exit strategy
- Policy enforces:
  - allowed destination asset (USDC)
  - max slippage
  - chain restriction

### Execution
- System monitors price drop
- When threshold is reached:
  - executes full or partial exit

### Why This Matters
- protects against major downside
- removes hesitation in volatile markets
- ensures execution even when user is offline

---

## 5. Policy-Enforced Transactions (Security-First Execution)

### Intent
"Only allow transactions on Base with trusted protocols"

### What Happens
- AI translates into strict security policy
- Policy enforces:
  - chain allowlist
  - contract restrictions
  - approval limitations

### Execution
- Any proposed action:
  - is validated against policy
  - blocked if unsafe

### Example Rejection
Proposed route: Ethereum Mainnet
Blocked: Chain not allowed by policy


### Why This Matters
- prevents unsafe interactions
- protects users from malicious routes/contracts
- adds a security layer to automation

---

## 6. Time-Bound Execution (Opportunistic Actions)

### Intent
"Swap USDC to ETH if a good rate appears in the next 6 hours"

### What Happens
- AI defines “good rate” threshold
- Policy enforces:
  - expiry window
  - minimum expected output

### Execution
- System scans for favorable routes
- Executes only if threshold is met before expiry

### Why This Matters
- captures short-term opportunities
- avoids bad trades
- gives user bounded automation

---

## What We Intentionally Do NOT Support

To maintain safety and clarity, IntentGuard avoids:

- high-frequency trading bots
- unrestricted AI decision-making
- fully autonomous “profit-seeking” agents
- complex leveraged strategies

---

## Summary

IntentGuard focuses on:

- condition-based execution  
- route optimization  
- portfolio automation  
- risk management  
- security enforcement  

All powered by:
- AI-generated policies  
- deterministic execution  
- Zerion CLI as the onchain engine  

The result is a system that is:
- practical  
- safe  
- and immediately usable  