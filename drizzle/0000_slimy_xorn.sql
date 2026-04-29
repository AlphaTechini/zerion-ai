CREATE TYPE "public"."action_type" AS ENUM('swap', 'bridge', 'send', 'rebalance', 'block_only');--> statement-breakpoint
CREATE TYPE "public"."ai_council_decision" AS ENUM('approved', 'rejected', 'needs_user_edit');--> statement-breakpoint
CREATE TYPE "public"."approval_status" AS ENUM('required', 'submitted', 'confirmed', 'failed', 'blocked');--> statement-breakpoint
CREATE TYPE "public"."chain_type" AS ENUM('evm', 'solana');--> statement-breakpoint
CREATE TYPE "public"."execution_status" AS ENUM('pending', 'trigger_validated', 'quote_requested', 'quote_received', 'route_selected', 'policy_validated', 'approval_required', 'approval_submitted', 'approval_confirmed', 'signed', 'submitted', 'confirmed', 'timeout', 'blocked', 'failed');--> statement-breakpoint
CREATE TYPE "public"."execution_type" AS ENUM('swap', 'bridge', 'send', 'rebalance', 'blocked');--> statement-breakpoint
CREATE TYPE "public"."intent_status" AS ENUM('draft', 'reviewing', 'active', 'paused', 'triggered', 'executing', 'executed', 'blocked', 'expired', 'failed', 'cancelled');--> statement-breakpoint
CREATE TYPE "public"."intent_type" AS ENUM('conditional_accumulation', 'route_optimization', 'portfolio_rebalance', 'risk_exit', 'security_policy', 'time_bound_execution', 'scheduled_dca');--> statement-breakpoint
CREATE TYPE "public"."log_level" AS ENUM('info', 'warning', 'error');--> statement-breakpoint
CREATE TYPE "public"."route_preference" AS ENUM('best_output', 'lowest_gas', 'fastest', 'balanced');--> statement-breakpoint
CREATE TYPE "public"."trigger_type" AS ENUM('price_drop', 'price_target', 'portfolio_drift', 'time_window', 'route_available', 'schedule', 'manual');--> statement-breakpoint
CREATE TYPE "public"."wallet_origin" AS ENUM('zerion_cli', 'imported', 'connected', 'external');--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text,
	"display_name" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "wallet_accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"wallet_id" uuid NOT NULL,
	"chain_type" "chain_type" NOT NULL,
	"chain_id" text,
	"caip2_chain_id" text,
	"address" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "wallets" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"zerion_wallet_id" text,
	"name" text NOT NULL,
	"label" text,
	"origin" "wallet_origin" DEFAULT 'zerion_cli' NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "ai_council_reviews" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"intent_id" uuid NOT NULL,
	"strategy_agent_output" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"risk_agent_output" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"security_agent_output" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"final_policy_summary" text,
	"final_policy_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"decision" "ai_council_decision" NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "intent_policies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"intent_id" uuid NOT NULL,
	"zerion_agent_policy_id" uuid,
	"action_type" "action_type" NOT NULL,
	"source_asset" text,
	"target_asset" text,
	"max_amount" numeric(36, 18),
	"max_amount_asset" text,
	"max_slippage_bps" integer,
	"daily_spend_limit" numeric(36, 18),
	"daily_spend_asset" text,
	"allowed_chains" text[],
	"blocked_chains" text[],
	"allowed_contracts" text[],
	"blocked_contracts" text[],
	"trusted_protocols_only" boolean DEFAULT false NOT NULL,
	"trigger_type" "trigger_type" NOT NULL,
	"trigger_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"route_preference" "route_preference" DEFAULT 'best_output' NOT NULL,
	"policy_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"is_active" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "intents" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"wallet_id" uuid NOT NULL,
	"title" text NOT NULL,
	"raw_intent" text NOT NULL,
	"intent_type" "intent_type" NOT NULL,
	"status" "intent_status" DEFAULT 'draft' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"expires_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "zerion_agent_policies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"wallet_id" uuid,
	"zerion_policy_id" text NOT NULL,
	"name" text NOT NULL,
	"rules" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"executable_path" text,
	"executable_config" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "zerion_agent_tokens" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"wallet_id" uuid NOT NULL,
	"zerion_token_id" text NOT NULL,
	"name" text NOT NULL,
	"policy_ids" text[] DEFAULT '{}'::text[] NOT NULL,
	"expires_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "execution_logs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"execution_id" uuid,
	"intent_id" uuid,
	"level" "log_level" NOT NULL,
	"event_type" text NOT NULL,
	"message" text NOT NULL,
	"metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "executions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"intent_id" uuid NOT NULL,
	"intent_policy_id" uuid NOT NULL,
	"wallet_id" uuid NOT NULL,
	"route_check_id" uuid,
	"agent_token_id" uuid,
	"execution_type" "execution_type" NOT NULL,
	"status" "execution_status" NOT NULL,
	"source_chain" text,
	"target_chain" text,
	"tx_hash" text,
	"block_number" bigint,
	"input_asset" text,
	"output_asset" text,
	"input_amount" numeric(36, 18),
	"expected_output_amount" numeric(36, 18),
	"actual_output_amount" numeric(36, 18),
	"gas_used" numeric(36, 0),
	"failure_reason" text,
	"blocked_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"signed_at" timestamp with time zone,
	"submitted_at" timestamp with time zone,
	"confirmed_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "route_checks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"intent_policy_id" uuid NOT NULL,
	"trigger_check_id" uuid,
	"provider" text DEFAULT 'zerion' NOT NULL,
	"zerion_offer_id" text,
	"liquidity_source" text,
	"source_chain" text,
	"target_chain" text,
	"source_asset" text,
	"target_asset" text,
	"source_asset_address" text,
	"target_asset_address" text,
	"input_amount" numeric(36, 18),
	"input_amount_raw" text,
	"expected_output_amount" numeric(36, 18),
	"minimum_output_amount" numeric(36, 18),
	"estimated_gas_usd" numeric(18, 8),
	"estimated_seconds" integer,
	"slippage_bps" integer,
	"slippage_type" text,
	"fee_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"preconditions_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"spender_address" text,
	"transaction_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"route_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"is_acceptable" boolean DEFAULT false NOT NULL,
	"rejection_reason" text,
	"checked_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "transaction_approvals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"execution_id" uuid NOT NULL,
	"chain" text NOT NULL,
	"token_address" text NOT NULL,
	"spender_address" text NOT NULL,
	"amount_raw" text NOT NULL,
	"status" "approval_status" NOT NULL,
	"tx_hash" text,
	"failure_reason" text,
	"blocked_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"submitted_at" timestamp with time zone,
	"confirmed_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "trigger_checks" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"intent_policy_id" uuid NOT NULL,
	"trigger_type" text NOT NULL,
	"check_payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"condition_met" boolean DEFAULT false NOT NULL,
	"reason" text,
	"checked_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_settings" (
	"user_id" uuid PRIMARY KEY NOT NULL,
	"default_max_slippage_bps" integer DEFAULT 150,
	"default_allowed_chains" text[],
	"default_daily_spend_limit" numeric(36, 18),
	"default_daily_spend_asset" text,
	"require_manual_confirmation" boolean DEFAULT false NOT NULL,
	"preferences" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "wallet_accounts" ADD CONSTRAINT "wallet_accounts_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "wallets" ADD CONSTRAINT "wallets_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "ai_council_reviews" ADD CONSTRAINT "ai_council_reviews_intent_id_intents_id_fk" FOREIGN KEY ("intent_id") REFERENCES "public"."intents"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "intent_policies" ADD CONSTRAINT "intent_policies_intent_id_intents_id_fk" FOREIGN KEY ("intent_id") REFERENCES "public"."intents"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "intent_policies" ADD CONSTRAINT "intent_policies_zerion_agent_policy_id_zerion_agent_policies_id_fk" FOREIGN KEY ("zerion_agent_policy_id") REFERENCES "public"."zerion_agent_policies"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "intents" ADD CONSTRAINT "intents_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "intents" ADD CONSTRAINT "intents_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "zerion_agent_policies" ADD CONSTRAINT "zerion_agent_policies_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "zerion_agent_tokens" ADD CONSTRAINT "zerion_agent_tokens_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "execution_logs" ADD CONSTRAINT "execution_logs_execution_id_executions_id_fk" FOREIGN KEY ("execution_id") REFERENCES "public"."executions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "execution_logs" ADD CONSTRAINT "execution_logs_intent_id_intents_id_fk" FOREIGN KEY ("intent_id") REFERENCES "public"."intents"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "executions" ADD CONSTRAINT "executions_intent_id_intents_id_fk" FOREIGN KEY ("intent_id") REFERENCES "public"."intents"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "executions" ADD CONSTRAINT "executions_intent_policy_id_intent_policies_id_fk" FOREIGN KEY ("intent_policy_id") REFERENCES "public"."intent_policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "executions" ADD CONSTRAINT "executions_wallet_id_wallets_id_fk" FOREIGN KEY ("wallet_id") REFERENCES "public"."wallets"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "executions" ADD CONSTRAINT "executions_route_check_id_route_checks_id_fk" FOREIGN KEY ("route_check_id") REFERENCES "public"."route_checks"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "executions" ADD CONSTRAINT "executions_agent_token_id_zerion_agent_tokens_id_fk" FOREIGN KEY ("agent_token_id") REFERENCES "public"."zerion_agent_tokens"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "route_checks" ADD CONSTRAINT "route_checks_intent_policy_id_intent_policies_id_fk" FOREIGN KEY ("intent_policy_id") REFERENCES "public"."intent_policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "route_checks" ADD CONSTRAINT "route_checks_trigger_check_id_trigger_checks_id_fk" FOREIGN KEY ("trigger_check_id") REFERENCES "public"."trigger_checks"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_approvals" ADD CONSTRAINT "transaction_approvals_execution_id_executions_id_fk" FOREIGN KEY ("execution_id") REFERENCES "public"."executions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trigger_checks" ADD CONSTRAINT "trigger_checks_intent_policy_id_intent_policies_id_fk" FOREIGN KEY ("intent_policy_id") REFERENCES "public"."intent_policies"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_settings" ADD CONSTRAINT "user_settings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_wallet_accounts_wallet_id" ON "wallet_accounts" USING btree ("wallet_id");--> statement-breakpoint
CREATE INDEX "idx_wallet_accounts_address" ON "wallet_accounts" USING btree ("address");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_wallet_accounts_wallet_chain_address_unique" ON "wallet_accounts" USING btree ("wallet_id","chain_type","address");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_wallet_accounts_chain_address_unique" ON "wallet_accounts" USING btree ("chain_type","address");--> statement-breakpoint
CREATE INDEX "idx_wallets_user_id" ON "wallets" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_wallets_user_name_unique" ON "wallets" USING btree ("user_id","name");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_wallets_user_zerion_wallet_id_unique" ON "wallets" USING btree ("user_id","zerion_wallet_id") WHERE "wallets"."zerion_wallet_id" IS NOT NULL;--> statement-breakpoint
CREATE INDEX "idx_intent_policies_intent_id" ON "intent_policies" USING btree ("intent_id");--> statement-breakpoint
CREATE INDEX "idx_intent_policies_active" ON "intent_policies" USING btree ("is_active");--> statement-breakpoint
CREATE INDEX "idx_intent_policies_expires_at" ON "intent_policies" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "idx_intents_user_id" ON "intents" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_intents_wallet_id" ON "intents" USING btree ("wallet_id");--> statement-breakpoint
CREATE INDEX "idx_intents_status" ON "intents" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_intents_expires_at" ON "intents" USING btree ("expires_at");--> statement-breakpoint
CREATE INDEX "idx_zerion_agent_policies_wallet_id" ON "zerion_agent_policies" USING btree ("wallet_id");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_zerion_agent_policies_policy_id_unique" ON "zerion_agent_policies" USING btree ("zerion_policy_id");--> statement-breakpoint
CREATE INDEX "idx_zerion_agent_tokens_wallet_id" ON "zerion_agent_tokens" USING btree ("wallet_id");--> statement-breakpoint
CREATE INDEX "idx_zerion_agent_tokens_expires_at" ON "zerion_agent_tokens" USING btree ("expires_at");--> statement-breakpoint
CREATE UNIQUE INDEX "idx_zerion_agent_tokens_token_id_unique" ON "zerion_agent_tokens" USING btree ("zerion_token_id");--> statement-breakpoint
CREATE INDEX "idx_execution_logs_execution_id" ON "execution_logs" USING btree ("execution_id");--> statement-breakpoint
CREATE INDEX "idx_execution_logs_intent_id" ON "execution_logs" USING btree ("intent_id");--> statement-breakpoint
CREATE INDEX "idx_executions_intent_id" ON "executions" USING btree ("intent_id");--> statement-breakpoint
CREATE INDEX "idx_executions_policy_id" ON "executions" USING btree ("intent_policy_id");--> statement-breakpoint
CREATE INDEX "idx_executions_status" ON "executions" USING btree ("status");--> statement-breakpoint
CREATE INDEX "idx_executions_tx_hash" ON "executions" USING btree ("tx_hash");--> statement-breakpoint
CREATE INDEX "idx_route_checks_policy_id" ON "route_checks" USING btree ("intent_policy_id");--> statement-breakpoint
CREATE INDEX "idx_route_checks_offer_id" ON "route_checks" USING btree ("zerion_offer_id");--> statement-breakpoint
CREATE INDEX "idx_transaction_approvals_execution_id" ON "transaction_approvals" USING btree ("execution_id");--> statement-breakpoint
CREATE INDEX "idx_trigger_checks_policy_id" ON "trigger_checks" USING btree ("intent_policy_id");