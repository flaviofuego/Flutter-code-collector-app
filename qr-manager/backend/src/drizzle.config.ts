import { defineConfig } from "drizzle-kit";
import { envConfig } from "./config/env.config";

export default defineConfig({
  dialect: "postgresql",
  schema: "./db/schema.ts",
  out: "./drizzle",
  dbCredentials: {
    host: envConfig.database.host,
    port: envConfig.database.port,
    database: envConfig.database.name,
    user: envConfig.database.user,
    password: envConfig.database.password,
    ssl: false,
  },
});
