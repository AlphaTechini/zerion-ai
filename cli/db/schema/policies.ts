import { sql } from "drizzle-orm";
import {
  boolean,
  index,
  integer,
  jsonb,
  numeric,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  pgTable,
} from "drizzle-orm/pg-core";
import {
  actionTypeEnum,
  aiCouncilDecisionEnum,
  intentStatusEnum,
  intentTypeEnum,
  routePreferenceEnum,
  triggerTypeEnum,
} from "./enums.js";
import { users, wallets } from "./identity.js";

export const zerionAgentPolicies = pgTable(
  "zerion_agent_policies",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    walletId: uuid("wallet_id").references(() => wallets.id, { onDelete: "cascade" }),
    zerionPolicyId: text("zerion_policy_id").notNull(),
    name: text("name").notNull(),
    rules: jsonb("rules").default(sql`'[]'::jsonb`).notNull(),
    executablePath: text("executable_path"),
    executableConfig: jsonb("executable_config").default(sql`'{}'::jsonb`).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    deletedAt: timestamp("deleted_at", { withTimezone: true }),
  },
  (table) => [
    index("idx_zerion_agent_policies_wallet_id").on(table.walletId),
    uniqueIndex("idx_zerion_agent_policies_policy_id_unique").on(table.zerionPolicyId),
  ],
);

export const zerionAgentTokens = pgTable(
  "zerion_agent_tokens",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    walletId: uuid("wallet_id")
      .notNull()
      .references(() => wallets.id, { onDelete: "cascade" }),
    zerionTokenId: text("zerion_token_id").notNull(),
    name: text("name").notNull(),
    policyIds: text("policy_ids").array().default(sql`'{}'::text[]`).notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    revokedAt: timestamp("revoked_at", { withTimezone: true }),
  },
  (table) => [
    index("idx_zerion_agent_tokens_wallet_id").on(table.walletId),
    index("idx_zerion_agent_tokens_expires_at").on(table.expiresAt),
    uniqueIndex("idx_zerion_agent_tokens_token_id_unique").on(table.zerionTokenId),
  ],
);

export const intents = pgTable(
  "intents",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    walletId: uuid("wallet_id")
      .notNull()
      .references(() => wallets.id, { onDelete: "cascade" }),
    title: text("title").notNull(),
    rawIntent: text("raw_intent").notNull(),
    intentType: intentTypeEnum("intent_type").notNull(),
    status: intentStatusEnum("status").default("draft").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
  },
  (table) => [
    index("idx_intents_user_id").on(table.userId),
    index("idx_intents_wallet_id").on(table.walletId),
    index("idx_intents_status").on(table.status),
    index("idx_intents_expires_at").on(table.expiresAt),
  ],
);

export const intentPolicies = pgTable(
  "intent_policies",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    intentId: uuid("intent_id")
      .notNull()
      .references(() => intents.id, { onDelete: "cascade" }),
    zerionAgentPolicyId: uuid("zerion_agent_policy_id").references(() => zerionAgentPolicies.id, {
      onDelete: "set null",
    }),
    actionType: actionTypeEnum("action_type").notNull(),
    sourceAsset: text("source_asset"),
    targetAsset: text("target_asset"),
    maxAmount: numeric("max_amount", { precision: 36, scale: 18 }),
    maxAmountAsset: text("max_amount_asset"),
    maxSlippageBps: integer("max_slippage_bps"),
    dailySpendLimit: numeric("daily_spend_limit", { precision: 36, scale: 18 }),
    dailySpendAsset: text("daily_spend_asset"),
    allowedChains: text("allowed_chains").array(),
    blockedChains: text("blocked_chains").array(),
    allowedContracts: text("allowed_contracts").array(),
    blockedContracts: text("blocked_contracts").array(),
    trustedProtocolsOnly: boolean("trusted_protocols_only").default(false).notNull(),
    triggerType: triggerTypeEnum("trigger_type").notNull(),
    triggerConfig: jsonb("trigger_config").default(sql`'{}'::jsonb`).notNull(),
    routePreference: routePreferenceEnum("route_preference").default("best_output").notNull(),
    policyConfig: jsonb("policy_config").default(sql`'{}'::jsonb`).notNull(),
    isActive: boolean("is_active").default(false).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }),
  },
  (table) => [
    index("idx_intent_policies_intent_id").on(table.intentId),
    index("idx_intent_policies_active").on(table.isActive),
    index("idx_intent_policies_expires_at").on(table.expiresAt),
  ],
);

export const aiCouncilReviews = pgTable("ai_council_reviews", {
  id: uuid("id").defaultRandom().primaryKey(),
  intentId: uuid("intent_id")
    .notNull()
    .references(() => intents.id, { onDelete: "cascade" }),
  strategyAgentOutput: jsonb("strategy_agent_output").default(sql`'{}'::jsonb`).notNull(),
  riskAgentOutput: jsonb("risk_agent_output").default(sql`'{}'::jsonb`).notNull(),
  securityAgentOutput: jsonb("security_agent_output").default(sql`'{}'::jsonb`).notNull(),
  finalPolicySummary: text("final_policy_summary"),
  finalPolicyJson: jsonb("final_policy_json").default(sql`'{}'::jsonb`).notNull(),
  decision: aiCouncilDecisionEnum("decision").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
});
