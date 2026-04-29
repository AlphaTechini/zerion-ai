import { pgEnum } from "drizzle-orm/pg-core";

export const walletOriginEnum = pgEnum("wallet_origin", [
  "zerion_cli",
  "imported",
  "connected",
  "external",
]);

export const chainTypeEnum = pgEnum("chain_type", ["evm", "solana"]);

export const intentTypeEnum = pgEnum("intent_type", [
  "conditional_accumulation",
  "route_optimization",
  "portfolio_rebalance",
  "risk_exit",
  "security_policy",
  "time_bound_execution",
  "scheduled_dca",
]);

export const intentStatusEnum = pgEnum("intent_status", [
  "draft",
  "reviewing",
  "active",
  "paused",
  "triggered",
  "executing",
  "executed",
  "blocked",
  "expired",
  "failed",
  "cancelled",
]);

export const actionTypeEnum = pgEnum("action_type", [
  "swap",
  "bridge",
  "send",
  "rebalance",
  "block_only",
]);

export const triggerTypeEnum = pgEnum("trigger_type", [
  "price_drop",
  "price_target",
  "portfolio_drift",
  "time_window",
  "route_available",
  "schedule",
  "manual",
]);

export const routePreferenceEnum = pgEnum("route_preference", [
  "best_output",
  "lowest_gas",
  "fastest",
  "balanced",
]);

export const executionTypeEnum = pgEnum("execution_type", [
  "swap",
  "bridge",
  "send",
  "rebalance",
  "blocked",
]);

export const executionStatusEnum = pgEnum("execution_status", [
  "pending",
  "trigger_validated",
  "quote_requested",
  "quote_received",
  "route_selected",
  "policy_validated",
  "approval_required",
  "approval_submitted",
  "approval_confirmed",
  "signed",
  "submitted",
  "confirmed",
  "timeout",
  "blocked",
  "failed",
]);

export const approvalStatusEnum = pgEnum("approval_status", [
  "required",
  "submitted",
  "confirmed",
  "failed",
  "blocked",
]);

export const logLevelEnum = pgEnum("log_level", ["info", "warning", "error"]);

export const aiCouncilDecisionEnum = pgEnum("ai_council_decision", [
  "approved",
  "rejected",
  "needs_user_edit",
]);
