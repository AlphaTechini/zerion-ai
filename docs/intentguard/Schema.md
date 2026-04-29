# Schema - IntentGuard

## Database Choice

Use **PostgreSQL** with Drizzle.

Reason:
- Financial actions need consistency.
- Policies need auditability.
- Executions must be traceable from intent to transaction hash.
- JSONB gives flexibility for AI-generated rules and raw Zerion API payloads.

The database is the IntentGuard control and audit plane. It must not store wallet private keys, seed phrases, passphrases, or raw Zerion agent-token secrets.

---

## Updated Zerion-Aware Model

Zerion CLI uses Open Wallet Standard (OWS) for local wallet management. One OWS wallet can expose multiple accounts, such as an EVM account and a Solana account.

Because of that, IntentGuard should split wallet identity from chain accounts:

```txt
users
  -> wallets
    -> wallet_accounts
    -> zerion_agent_tokens
      -> zerion_agent_policies
  -> intents
    -> intent_policies
      -> trigger_checks
      -> route_checks
      -> executions
        -> transaction_approvals
        -> execution_logs
```

---

## Table 1: users

Stores basic user identity.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## Table 2: wallets

Stores one logical Zerion/OWS wallet. This is not the same as one chain address.

To find wallet creation and formatting logic visit [../../cli/utils/wallet/keystore.js](file:///C:/Hackathons/Zerion%20CLI/cli/utils/wallet/keystore.js).

```sql
CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  zerion_wallet_id TEXT,
  name TEXT NOT NULL,
  label TEXT,
  origin TEXT NOT NULL DEFAULT 'zerion_cli' CHECK (
    origin IN ('zerion_cli', 'imported', 'connected', 'external')
  ),

  is_default BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, name),
  UNIQUE(user_id, zerion_wallet_id)
);
```

Decision:
- Store wallet identity and OWS reference here.
- Store addresses in `wallet_accounts`.

Tradeoff:
- Slightly more joins, but the schema matches how Zerion actually represents wallets across EVM and Solana.

---

## Table 3: wallet_accounts

Stores chain-specific accounts under a logical wallet.

```sql
CREATE TABLE wallet_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,

  chain_type TEXT NOT NULL CHECK (chain_type IN ('evm', 'solana')),
  chain_id TEXT,
  caip2_chain_id TEXT,
  address TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(wallet_id, chain_type, address),
  UNIQUE(chain_type, address)
);
```

Examples:
- EVM account: `chain_type = 'evm'`, `address = '0x...'`.
- Solana account: `chain_type = 'solana'`, `address = '...'`.

---

## Table 4: zerion_agent_policies

Stores metadata and snapshots for Zerion/OWS policies.

Zerion policies are the execution-layer guardrails. Current CLI-supported policy primitives include allowed chains, expiry, deny transfers, deny approvals, and allowlists.

To find Zerion policy creation logic visit [../../cli/commands/agent/create-policy.js](file:///C:/Hackathons/Zerion%20CLI/cli/commands/agent/create-policy.js).

```sql
CREATE TABLE zerion_agent_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,

  zerion_policy_id TEXT NOT NULL,
  name TEXT NOT NULL,

  rules JSONB NOT NULL DEFAULT '[]'::jsonb,
  executable_path TEXT,
  executable_config JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,

  UNIQUE(zerion_policy_id)
);
```

Decision:
- Keep Zerion policy snapshots for auditability.
- Do not assume Zerion policies cover every IntentGuard rule.

---

## Table 5: zerion_agent_tokens

Stores agent-token metadata only.

Never store the raw agent token value. Agent tokens are credentials with spending power and must remain in OWS config, local secure storage, or environment-managed runtime secrets.

To find agent token creation logic visit [../../cli/utils/wallet/keystore.js](file:///C:/Hackathons/Zerion%20CLI/cli/utils/wallet/keystore.js).

```sql
CREATE TABLE zerion_agent_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,

  zerion_token_id TEXT NOT NULL,
  name TEXT NOT NULL,
  policy_ids TEXT[] NOT NULL DEFAULT '{}',

  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,

  UNIQUE(zerion_token_id)
);
```

Decision:
- Store token id, wallet binding, policy ids, expiry, and revocation state.
- Do not store token secret material.

Tradeoff:
- The app may need runtime access to `ZERION_AGENT_TOKEN` or the local Zerion config to execute. That is safer than placing the secret in Postgres.

---

## Table 6: intents

Stores the user's high-level goal.

```sql
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
      'time_bound_execution',
      'scheduled_dca'
    )
  ),

  status TEXT NOT NULL DEFAULT 'draft' CHECK (
    status IN (
      'draft',
      'reviewing',
      'active',
      'paused',
      'triggered',
      'executing',
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
```

---

## Table 7: intent_policies

Stores IntentGuard's compiled policy. This is the primary policy engine for the agent.

IntentGuard policies are richer than Zerion policies. They can include max spend, max slippage, trigger conditions, route preferences, cooldowns, and trusted-protocol rules.

```sql
CREATE TABLE intent_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES intents(id) ON DELETE CASCADE,
  zerion_agent_policy_id UUID REFERENCES zerion_agent_policies(id) ON DELETE SET NULL,

  action_type TEXT NOT NULL CHECK (
    action_type IN ('swap', 'bridge', 'send', 'rebalance', 'block_only')
  ),

  source_asset TEXT,
  target_asset TEXT,

  max_amount NUMERIC(36, 18),
  max_amount_asset TEXT,
  max_slippage_bps INTEGER,
  daily_spend_limit NUMERIC(36, 18),
  daily_spend_asset TEXT,

  allowed_chains TEXT[],
  blocked_chains TEXT[],
  allowed_contracts TEXT[],
  blocked_contracts TEXT[],
  trusted_protocols_only BOOLEAN NOT NULL DEFAULT FALSE,

  trigger_type TEXT NOT NULL CHECK (
    trigger_type IN (
      'price_drop',
      'price_target',
      'portfolio_drift',
      'time_window',
      'route_available',
      'schedule',
      'manual'
    )
  ),

  trigger_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  route_preference TEXT NOT NULL DEFAULT 'best_output' CHECK (
    route_preference IN ('best_output', 'lowest_gas', 'fastest', 'balanced')
  ),
  policy_config JSONB NOT NULL DEFAULT '{}'::jsonb,

  is_active BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);
```

Decision:
- Keep IntentGuard policy enforcement separate from Zerion/OWS policy enforcement.
- Link to Zerion policy when one exists, but do not depend on it for all safety checks.

---

## Table 8: ai_council_reviews

Stores AI reasoning and policy proposals.

```sql
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
```

---

## Table 9: trigger_checks

Stores background worker checks before route discovery or execution.

```sql
CREATE TABLE trigger_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_policy_id UUID NOT NULL REFERENCES intent_policies(id) ON DELETE CASCADE,

  trigger_type TEXT NOT NULL,
  check_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  condition_met BOOLEAN NOT NULL DEFAULT FALSE,
  reason TEXT,

  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## Table 10: route_checks

Stores Zerion route or offer checks before execution.

To find Zerion quote shaping logic visit [../../cli/utils/trading/swap.js](file:///C:/Hackathons/Zerion%20CLI/cli/utils/trading/swap.js).

```sql
CREATE TABLE route_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_policy_id UUID NOT NULL REFERENCES intent_policies(id) ON DELETE CASCADE,
  trigger_check_id UUID REFERENCES trigger_checks(id) ON DELETE SET NULL,

  provider TEXT NOT NULL DEFAULT 'zerion',
  zerion_offer_id TEXT,
  liquidity_source TEXT,

  source_chain TEXT,
  target_chain TEXT,
  source_asset TEXT,
  target_asset TEXT,
  source_asset_address TEXT,
  target_asset_address TEXT,

  input_amount NUMERIC(36, 18),
  input_amount_raw TEXT,
  expected_output_amount NUMERIC(36, 18),
  minimum_output_amount NUMERIC(36, 18),
  estimated_gas_usd NUMERIC(18, 8),
  estimated_seconds INTEGER,

  slippage_bps INTEGER,
  slippage_type TEXT,
  fee_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  preconditions_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  spender_address TEXT,
  transaction_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  route_payload JSONB NOT NULL DEFAULT '{}'::jsonb,

  is_acceptable BOOLEAN NOT NULL DEFAULT FALSE,
  rejection_reason TEXT,

  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Decision:
- Store both normalized route fields and the raw Zerion payload.
- Keep `transaction_payload` because Zerion swap offers include ready-to-sign transaction data.

---

## Table 11: executions

Stores actual or attempted autonomous executions.

To find EVM signing and broadcast logic visit [../../cli/utils/trading/transaction.js](file:///C:/Hackathons/Zerion%20CLI/cli/utils/trading/transaction.js).

```sql
CREATE TABLE executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id UUID NOT NULL REFERENCES intents(id) ON DELETE CASCADE,
  intent_policy_id UUID NOT NULL REFERENCES intent_policies(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  route_check_id UUID REFERENCES route_checks(id) ON DELETE SET NULL,
  agent_token_id UUID REFERENCES zerion_agent_tokens(id) ON DELETE SET NULL,

  execution_type TEXT NOT NULL CHECK (
    execution_type IN ('swap', 'bridge', 'send', 'rebalance', 'blocked')
  ),

  status TEXT NOT NULL CHECK (
    status IN (
      'pending',
      'trigger_validated',
      'quote_requested',
      'quote_received',
      'route_selected',
      'policy_validated',
      'approval_required',
      'approval_submitted',
      'approval_confirmed',
      'signed',
      'submitted',
      'confirmed',
      'timeout',
      'blocked',
      'failed'
    )
  ),

  source_chain TEXT,
  target_chain TEXT,
  tx_hash TEXT,
  block_number BIGINT,

  input_asset TEXT,
  output_asset TEXT,
  input_amount NUMERIC(36, 18),
  expected_output_amount NUMERIC(36, 18),
  actual_output_amount NUMERIC(36, 18),
  gas_used NUMERIC(36, 0),

  failure_reason TEXT,
  blocked_reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  signed_at TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ
);
```

---

## Table 12: transaction_approvals

Stores ERC-20 approval transactions required before swaps.

Zerion swap execution may need an approval before the swap transaction. This should be auditable because approvals are security-sensitive.

```sql
CREATE TABLE transaction_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID NOT NULL REFERENCES executions(id) ON DELETE CASCADE,

  chain TEXT NOT NULL,
  token_address TEXT NOT NULL,
  spender_address TEXT NOT NULL,
  amount_raw TEXT NOT NULL,

  status TEXT NOT NULL CHECK (
    status IN ('required', 'submitted', 'confirmed', 'failed', 'blocked')
  ),

  tx_hash TEXT,
  failure_reason TEXT,
  blocked_reason TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ
);
```

Decision:
- Track approvals separately from swaps.
- Approval amounts should be exact amounts, not unlimited, matching the current CLI behavior.

---

## Table 13: execution_logs

Stores step-by-step audit logs.

```sql
CREATE TABLE execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID REFERENCES executions(id) ON DELETE CASCADE,
  intent_id UUID REFERENCES intents(id) ON DELETE CASCADE,

  level TEXT NOT NULL CHECK (level IN ('info', 'warning', 'error')),
  event_type TEXT NOT NULL,

  message TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

Decision:
- Allow logs to link to either an execution or an intent.
- This supports blocked pre-execution events where an execution row may not exist yet.

---

## Table 14: user_settings

Stores user-level risk defaults.

```sql
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,

  default_max_slippage_bps INTEGER DEFAULT 150,
  default_allowed_chains TEXT[],
  default_daily_spend_limit NUMERIC(36, 18),
  default_daily_spend_asset TEXT,

  require_manual_confirmation BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## Recommended Indexes

```sql
CREATE INDEX idx_wallets_user_id ON wallets(user_id);
CREATE INDEX idx_wallet_accounts_wallet_id ON wallet_accounts(wallet_id);
CREATE INDEX idx_wallet_accounts_address ON wallet_accounts(address);

CREATE INDEX idx_zerion_agent_tokens_wallet_id ON zerion_agent_tokens(wallet_id);
CREATE INDEX idx_zerion_agent_tokens_expires_at ON zerion_agent_tokens(expires_at);
CREATE INDEX idx_zerion_agent_policies_wallet_id ON zerion_agent_policies(wallet_id);

CREATE INDEX idx_intents_user_id ON intents(user_id);
CREATE INDEX idx_intents_wallet_id ON intents(wallet_id);
CREATE INDEX idx_intents_status ON intents(status);
CREATE INDEX idx_intents_expires_at ON intents(expires_at);

CREATE INDEX idx_intent_policies_intent_id ON intent_policies(intent_id);
CREATE INDEX idx_intent_policies_active ON intent_policies(is_active);
CREATE INDEX idx_intent_policies_expires_at ON intent_policies(expires_at);

CREATE INDEX idx_trigger_checks_policy_id ON trigger_checks(intent_policy_id);
CREATE INDEX idx_route_checks_policy_id ON route_checks(intent_policy_id);
CREATE INDEX idx_route_checks_offer_id ON route_checks(zerion_offer_id);

CREATE INDEX idx_executions_intent_id ON executions(intent_id);
CREATE INDEX idx_executions_policy_id ON executions(intent_policy_id);
CREATE INDEX idx_executions_status ON executions(status);
CREATE INDEX idx_executions_tx_hash ON executions(tx_hash);

CREATE INDEX idx_transaction_approvals_execution_id ON transaction_approvals(execution_id);
CREATE INDEX idx_execution_logs_execution_id ON execution_logs(execution_id);
CREATE INDEX idx_execution_logs_intent_id ON execution_logs(intent_id);
```

---

## Status Lifecycle

Intent status:

```txt
draft -> reviewing -> active -> triggered -> executing -> executed
active -> paused
active -> blocked
active -> expired
active -> cancelled
triggered -> failed
executing -> failed
```

Execution status:

```txt
pending
-> trigger_validated
-> quote_requested
-> quote_received
-> route_selected
-> policy_validated
-> approval_required
-> approval_submitted
-> approval_confirmed
-> signed
-> submitted
-> confirmed

Any stage can move to:
blocked
failed
timeout
```

---

## Policy Enforcement Model

Before execution, IntentGuard checks:

- Is the intent active?
- Is the policy active?
- Has the policy expired?
- Is the trigger condition met?
- Is the action type allowed?
- Is the chain allowed?
- Is the amount within max spend?
- Is the daily spend limit still available?
- Is slippage within limit?
- Is the route provider acceptable?
- Is the spender or contract allowed?
- Are approvals allowed by the policy?
- Is a valid agent token available at runtime?
- Is the linked Zerion policy present when required?

Only after those checks pass should the CLI sign or broadcast.

Zerion/OWS policies remain a secondary execution safety layer. IntentGuard policy validation remains the primary application safety layer.

---

## JSONB Usage

Use JSONB for flexible or provider-shaped fields only:

```json
{
  "trigger_config": {
    "asset": "ETH",
    "condition": "price_drop",
    "percent": 5,
    "window": "24h"
  },
  "policy_config": {
    "cooldown_minutes": 60,
    "trusted_protocols_only": true,
    "manual_confirmation_above": "250"
  },
  "route_payload": {
    "source": "raw Zerion offer response"
  },
  "metadata": {
    "source": "execution logs, debugging details, and CLI responses"
  }
}
```

Avoid JSONB for fields that must be indexed, filtered, or enforced regularly. Those should be first-class columns.

---

## Final Notes

This schema is designed for:

- Safe autonomous execution.
- Explainable AI decisions.
- Strict IntentGuard policy enforcement.
- Secondary Zerion/OWS policy tracking.
- Route and approval auditability.
- Real onchain transaction tracking.

The Drizzle implementation should start with this model, then narrow fields based on the MVP route: likely a Base-only scheduled DCA or conditional swap agent.
