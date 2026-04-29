# Schema — IntentGuard

## Database Choice

Use **PostgreSQL**.

Reason:
- financial actions need consistency
- policies need auditability
- executions must be traceable
- JSONB still gives flexibility for AI-generated policy rules

---

## Core Relationships

```txt
users
  → wallets
  → intents
    → policies
    → executions
      → execution_logs

Tables
1. users

Stores basic user identity.

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
2. wallets

Stores connected or generated wallet references.

CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  address TEXT NOT NULL,
  chain_type TEXT NOT NULL CHECK (chain_type IN ('evm', 'solana')),
  label TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, address)
);
3. intents

Stores what the user wants to achieve.

CREATE TABLE intents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,

  title TEXT NOT NULL,
  raw_intent TEXT NOT NULL,

  intent_type TEXT NOT NULL CHECK (
    intent_type IN (
      'conditional_accumulation',
      'route_optimization',
      'portfolio_rebalance',
      'risk_exit',
      'security_policy',
      'time_bound_execution'
    )
  ),

  status TEXT NOT NULL DEFAULT 'draft' CHECK (
    status IN (
      'draft',
      'active',
      'paused',
      'triggered',
      'executed',
      'blocked',
      'expired',
      'failed',
      'cancelled'
    )
  ),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);
4. policies

Stores compiled execution rules generated from user intent.

CREATE TABLE policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES intents(id) ON DELETE CASCADE,

  action_type TEXT NOT NULL CHECK (
    action_type IN ('swap', 'bridge', 'send', 'rebalance', 'block_only')
  ),

  source_asset TEXT,
  target_asset TEXT,

  max_amount NUMERIC(36, 18),
  max_slippage_bps INTEGER,
  allowed_chains TEXT[],
  blocked_chains TEXT[],
  allowed_contracts TEXT[],
  blocked_contracts TEXT[],

  trigger_type TEXT NOT NULL CHECK (
    trigger_type IN (
      'price_drop',
      'price_target',
      'portfolio_drift',
      'time_window',
      'route_available',
      'manual'
    )
  ),

  trigger_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  policy_config JSONB NOT NULL DEFAULT '{}'::jsonb,

  is_active BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);
5. ai_council_reviews

Stores AI reasoning and policy proposals.

CREATE TABLE ai_council_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES intents(id) ON DELETE CASCADE,

  strategy_agent_output JSONB NOT NULL DEFAULT '{}'::jsonb,
  risk_agent_output JSONB NOT NULL DEFAULT '{}'::jsonb,
  security_agent_output JSONB NOT NULL DEFAULT '{}'::jsonb,

  final_policy_summary TEXT,
  final_policy_json JSONB NOT NULL DEFAULT '{}'::jsonb,

  decision TEXT NOT NULL CHECK (
    decision IN ('approved', 'rejected', 'needs_user_edit')
  ),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
6. executions

Stores actual or attempted onchain executions.

CREATE TABLE executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES intents(id) ON DELETE CASCADE,
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,

  execution_type TEXT NOT NULL CHECK (
    execution_type IN ('swap', 'bridge', 'send', 'rebalance', 'blocked')
  ),

  status TEXT NOT NULL CHECK (
    status IN (
      'pending',
      'route_found',
      'policy_validated',
      'submitted',
      'confirmed',
      'blocked',
      'failed'
    )
  ),

  zerion_route_id TEXT,
  chain TEXT,
  tx_hash TEXT,

  input_asset TEXT,
  output_asset TEXT,
  input_amount NUMERIC(36, 18),
  expected_output_amount NUMERIC(36, 18),
  actual_output_amount NUMERIC(36, 18),

  failure_reason TEXT,
  blocked_reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ
);
7. execution_logs

Stores step-by-step audit logs.

CREATE TABLE execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID NOT NULL REFERENCES executions(id) ON DELETE CASCADE,

  level TEXT NOT NULL CHECK (level IN ('info', 'warning', 'error')),
  event_type TEXT NOT NULL,

  message TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
8. route_checks

Stores route checks before execution.

CREATE TABLE route_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,

  provider TEXT DEFAULT 'zerion',
  source_chain TEXT,
  target_chain TEXT,

  source_asset TEXT,
  target_asset TEXT,

  input_amount NUMERIC(36, 18),
  expected_output_amount NUMERIC(36, 18),
  estimated_gas_usd NUMERIC(18, 8),
  slippage_bps INTEGER,

  route_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  is_acceptable BOOLEAN NOT NULL DEFAULT FALSE,
  rejection_reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
9. trigger_checks

Stores background worker checks.

CREATE TABLE trigger_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID NOT NULL REFERENCES policies(id) ON DELETE CASCADE,

  trigger_type TEXT NOT NULL,
  check_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  condition_met BOOLEAN NOT NULL DEFAULT FALSE,
  reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
10. user_settings

Stores user-level risk defaults.

CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

  default_max_slippage_bps INTEGER DEFAULT 150,
  default_allowed_chains TEXT[],
  default_daily_spend_limit NUMERIC(36, 18),

  require_manual_confirmation BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
Recommended Indexes
CREATE INDEX idx_wallets_user_id ON wallets(user_id);

CREATE INDEX idx_intents_user_id ON intents(user_id);
CREATE INDEX idx_intents_status ON intents(status);
CREATE INDEX idx_intents_expires_at ON intents(expires_at);

CREATE INDEX idx_policies_intent_id ON policies(intent_id);
CREATE INDEX idx_policies_active ON policies(is_active);
CREATE INDEX idx_policies_expires_at ON policies(expires_at);

CREATE INDEX idx_executions_intent_id ON executions(intent_id);
CREATE INDEX idx_executions_policy_id ON executions(policy_id);
CREATE INDEX idx_executions_status ON executions(status);
CREATE INDEX idx_executions_tx_hash ON executions(tx_hash);

CREATE INDEX idx_execution_logs_execution_id ON execution_logs(execution_id);

CREATE INDEX idx_route_checks_policy_id ON route_checks(policy_id);
CREATE INDEX idx_trigger_checks_policy_id ON trigger_checks(policy_id);
Status Lifecycle
Intent Status
draft
→ active
→ triggered
→ executed

active
→ blocked

active
→ expired

active
→ paused

active
→ cancelled

triggered
→ failed
Policy Enforcement Model

Before execution, system checks:

Is policy active?
Has policy expired?
Is chain allowed?
Is action type allowed?
Is amount within limit?
Is slippage within limit?
Is contract allowed?
Is trigger condition met?

Only then can Zerion CLI be called.

What Goes in JSONB

Use JSONB for flexible fields only:

trigger_config
{
  "asset": "ETH",
  "condition": "price_drop",
  "percent": 5,
  "window": "24h"
}
policy_config
{
  "route_preference": "best_output",
  "cooldown_minutes": 60,
  "trusted_protocols_only": true
}
route_payload

Raw Zerion route/offer response.

metadata

Execution logs, debugging details, and CLI responses.

Final Notes

This schema is designed for:

safe autonomous execution
explainable AI decisions
strict policy enforcement
audit logs
real onchain transaction tracking

The AI coding agent can refine table names, exact Zerion fields, and enums after reviewing the real Zerion CLI implementation.