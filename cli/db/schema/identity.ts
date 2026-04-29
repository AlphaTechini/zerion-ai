import { sql } from "drizzle-orm";
import {
  boolean,
  index,
  text,
  timestamp,
  uniqueIndex,
  uuid,
  pgTable,
} from "drizzle-orm/pg-core";
import { chainTypeEnum, walletOriginEnum } from "./enums.js";

export const users = pgTable("users", {
  id: uuid("id").defaultRandom().primaryKey(),
  email: text("email").unique(),
  displayName: text("display_name"),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
});

export const wallets = pgTable(
  "wallets",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    zerionWalletId: text("zerion_wallet_id"),
    name: text("name").notNull(),
    label: text("label"),
    origin: walletOriginEnum("origin").default("zerion_cli").notNull(),
    isDefault: boolean("is_default").default(false).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index("idx_wallets_user_id").on(table.userId),
    uniqueIndex("idx_wallets_user_name_unique").on(table.userId, table.name),
    uniqueIndex("idx_wallets_user_zerion_wallet_id_unique")
      .on(table.userId, table.zerionWalletId)
      .where(sql`${table.zerionWalletId} IS NOT NULL`),
  ],
);

export const walletAccounts = pgTable(
  "wallet_accounts",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    walletId: uuid("wallet_id")
      .notNull()
      .references(() => wallets.id, { onDelete: "cascade" }),
    chainType: chainTypeEnum("chain_type").notNull(),
    chainId: text("chain_id"),
    caip2ChainId: text("caip2_chain_id"),
    address: text("address").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    index("idx_wallet_accounts_wallet_id").on(table.walletId),
    index("idx_wallet_accounts_address").on(table.address),
    uniqueIndex("idx_wallet_accounts_wallet_chain_address_unique").on(
      table.walletId,
      table.chainType,
      table.address,
    ),
    uniqueIndex("idx_wallet_accounts_chain_address_unique").on(table.chainType, table.address),
  ],
);
