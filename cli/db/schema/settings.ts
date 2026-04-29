import { sql } from "drizzle-orm";
import {
  boolean,
  integer,
  jsonb,
  numeric,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";
import { users } from "./identity.js";

export const userSettings = pgTable("user_settings", {
  userId: uuid("user_id")
    .primaryKey()
    .references(() => users.id, { onDelete: "cascade" }),
  defaultMaxSlippageBps: integer("default_max_slippage_bps").default(150),
  defaultAllowedChains: text("default_allowed_chains").array(),
  defaultDailySpendLimit: numeric("default_daily_spend_limit", { precision: 36, scale: 18 }),
  defaultDailySpendAsset: text("default_daily_spend_asset"),
  requireManualConfirmation: boolean("require_manual_confirmation").default(false).notNull(),
  preferences: jsonb("preferences").default(sql`'{}'::jsonb`).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
});
