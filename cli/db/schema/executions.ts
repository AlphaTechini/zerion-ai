import { sql } from "drizzle-orm";
import {
  bigint,
  index,
  jsonb,
  numeric,
  integer,
  text,
  timestamp,
  uuid,
  pgTable,
  boolean,
} from "drizzle-orm/pg-core";
import {
  approvalStatusEnum,
  executionStatusEnum,
  executionTypeEnum,
  logLevelEnum,
} from "./enums.js";
import { wallets } from "./identity.js";
import { intentPolicies, intents, zerionAgentTokens } from "./policies.js";

export const triggerChecks = pgTable(
  "trigger_checks",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    intentPolicyId: uuid("intent_policy_id")
      .notNull()
      .references(() => intentPolicies.id, { onDelete: "cascade" }),
    triggerType: text("trigger_type").notNull(),
    checkPayload: jsonb("check_payload").default(sql`'{}'::jsonb`).notNull(),
    conditionMet: boolean("condition_met").default(false).notNull(),
    reason: text("reason"),
    checkedAt: timestamp("checked_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [index("idx_trigger_checks_policy_id").on(table.intentPolicyId)],
);

export const routeChecks = pgTable(
  "route_checks",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    intentPolicyId: uuid("intent_policy_id")
      .notNull()
      .references(() => intentPolicies.id, { onDelete: "cascade" }),
    triggerCheckId: uuid("trigger_check_id").references(() => triggerChecks.id, {
      onDelete: "set null",
    }),
    provider: text("provider").default("zerion").notNull(),
    zerionOfferId: text("zerion_offer_id"),
    liquiditySource: text("liquidity_source"),
    sourceChain: text("source_chain"),
    targetChain: text("target_chain"),
    sourceAsset: text("source_asset"),
    targetAsset: text("target_asset"),
    sourceAssetAddress: text("source_asset_address"),
    targetAssetAddress: text("target_asset_address"),
    inputAmount: numeric("input_amount", { precision: 36, scale: 18 }),
    inputAmountRaw: text("input_amount_raw"),
    expectedOutputAmount: numeric("expected_output_amount", { precision: 36, scale: 18 }),
    minimumOutputAmount: numeric("minimum_output_amount", { precision: 36, scale: 18 }),
    estimatedGasUsd: numeric("estimated_gas_usd", { precision: 18, scale: 8 }),
    estimatedSeconds: integer("estimated_seconds"),
    slippageBps: integer("slippage_bps"),
    slippageType: text("slippage_type"),
    feePayload: jsonb("fee_payload").default(sql`'{}'::jsonb`).notNull(),
    preconditionsPayload: jsonb("preconditions_payload").default(sql`'{}'::jsonb`).notNull(),
    spenderAddress: text("spender_address"),
    transactionPayload: jsonb("transaction_payload").default(sql`'{}'::jsonb`).notNull(),
    routePayload: jsonb("route_payload").default(sql`'{}'::jsonb`).notNull(),
    isAcceptable: boolean("is_acceptable").default(false).notNull(),
    rejectionReason: text("rejection_reason"),
    checkedAt: timestamp("checked_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index("idx_route_checks_policy_id").on(table.intentPolicyId),
    index("idx_route_checks_offer_id").on(table.zerionOfferId),
  ],
);

export const executions = pgTable(
  "executions",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    intentId: uuid("intent_id")
      .notNull()
      .references(() => intents.id, { onDelete: "cascade" }),
    intentPolicyId: uuid("intent_policy_id")
      .notNull()
      .references(() => intentPolicies.id, { onDelete: "cascade" }),
    walletId: uuid("wallet_id")
      .notNull()
      .references(() => wallets.id, { onDelete: "cascade" }),
    routeCheckId: uuid("route_check_id").references(() => routeChecks.id, {
      onDelete: "set null",
    }),
    agentTokenId: uuid("agent_token_id").references(() => zerionAgentTokens.id, {
      onDelete: "set null",
    }),
    executionType: executionTypeEnum("execution_type").notNull(),
    status: executionStatusEnum("status").notNull(),
    sourceChain: text("source_chain"),
    targetChain: text("target_chain"),
    txHash: text("tx_hash"),
    blockNumber: bigint("block_number", { mode: "number" }),
    inputAsset: text("input_asset"),
    outputAsset: text("output_asset"),
    inputAmount: numeric("input_amount", { precision: 36, scale: 18 }),
    expectedOutputAmount: numeric("expected_output_amount", { precision: 36, scale: 18 }),
    actualOutputAmount: numeric("actual_output_amount", { precision: 36, scale: 18 }),
    gasUsed: numeric("gas_used", { precision: 36, scale: 0 }),
    failureReason: text("failure_reason"),
    blockedReason: text("blocked_reason"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    signedAt: timestamp("signed_at", { withTimezone: true }),
    submittedAt: timestamp("submitted_at", { withTimezone: true }),
    confirmedAt: timestamp("confirmed_at", { withTimezone: true }),
  },
  (table) => [
    index("idx_executions_intent_id").on(table.intentId),
    index("idx_executions_policy_id").on(table.intentPolicyId),
    index("idx_executions_status").on(table.status),
    index("idx_executions_tx_hash").on(table.txHash),
  ],
);

export const transactionApprovals = pgTable(
  "transaction_approvals",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    executionId: uuid("execution_id")
      .notNull()
      .references(() => executions.id, { onDelete: "cascade" }),
    chain: text("chain").notNull(),
    tokenAddress: text("token_address").notNull(),
    spenderAddress: text("spender_address").notNull(),
    amountRaw: text("amount_raw").notNull(),
    status: approvalStatusEnum("status").notNull(),
    txHash: text("tx_hash"),
    failureReason: text("failure_reason"),
    blockedReason: text("blocked_reason"),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    submittedAt: timestamp("submitted_at", { withTimezone: true }),
    confirmedAt: timestamp("confirmed_at", { withTimezone: true }),
  },
  (table) => [index("idx_transaction_approvals_execution_id").on(table.executionId)],
);

export const executionLogs = pgTable(
  "execution_logs",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    executionId: uuid("execution_id").references(() => executions.id, {
      onDelete: "cascade",
    }),
    intentId: uuid("intent_id").references(() => intents.id, { onDelete: "cascade" }),
    level: logLevelEnum("level").notNull(),
    eventType: text("event_type").notNull(),
    message: text("message").notNull(),
    metadata: jsonb("metadata").default(sql`'{}'::jsonb`).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index("idx_execution_logs_execution_id").on(table.executionId),
    index("idx_execution_logs_intent_id").on(table.intentId),
  ],
);
