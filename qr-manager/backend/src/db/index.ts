import { Pool } from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { envConfig } from "../config/env.config";

const pool = new Pool({
  host: envConfig.database.host,
  port: envConfig.database.port,
  database: envConfig.database.name,
  user: envConfig.database.user,
  password: envConfig.database.password,
});

export const db = drizzle(pool);
