# User Flow — Intent-Based Autonomous Onchain Agent (Zerion CLI)

## Overview

This application allows users to define high-level financial intents, which are converted into constrained execution policies by an AI council. These policies are monitored and executed automatically using Zerion CLI when conditions are met.

The system prioritizes:
- user control
- transparent automation
- safe onchain execution

---

## Entry Point

### Landing Page

User is presented with two primary CTAs:

1. **Create an Intent** (primary)
2. **Explore Demo** (secondary)

---

## Flow 1: Create an Intent

### Step 1: Intent Definition

User defines what they want to achieve.

Options:
- Select from predefined templates:
  - Accumulate ETH
  - Convert USDC to ETH at best rate
  - Rebalance portfolio
  - Exit risky positions
- Or enter freeform intent:
  - "Buy ETH if price drops 5%"
  - "Bridge funds to cheapest chain and swap"

---

### Step 2: Constraint Configuration

User sets boundaries for execution.

Required inputs:
- Max amount to use
- Allowed chains (e.g. Base, Arbitrum)
- Max slippage
- Expiry duration

Optional constraints:
- Only allow trusted protocols
- Block unknown contract approvals
- Limit transactions per day

---

### Step 3: AI Council Processing

System processes intent using multiple agents:

- Strategy Agent → defines execution approach
- Risk Agent → limits exposure
- Security Agent → enforces safety constraints

Output:
- structured execution policy

Example:
```json
{
  "action": "swap",
  "asset_from": "USDC",
  "asset_to": "ETH",
  "trigger": "price_drop_5_percent",
  "max_amount": "100 USDC",
  "chain": "Base",
  "slippage": 1.5,
  "expiry": "24h"
}