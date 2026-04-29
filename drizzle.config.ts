import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./cli/db/schema/index.ts",
  out: "./drizzle",
  dialect: "postgresql",
  strict: true,
  verbose: true,
  ...(process.env.DATABASE_URL
    ? { dbCredentials: { url: process.env.DATABASE_URL } }
    : {}),
});
