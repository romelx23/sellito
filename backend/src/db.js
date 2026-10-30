const Database = require('better-sqlite3');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'sella.db');
const DATA_DIR = path.dirname(DB_PATH);
const UPLOAD_DIR = path.join(DATA_DIR, 'uploads');

fs.mkdirSync(DATA_DIR, { recursive: true });
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

const now = () => new Date().toISOString();
const id = () => crypto.randomUUID();

const SCHEMA = `
CREATE TABLE IF NOT EXISTS businesses (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  logo_url    TEXT,
  brand_color TEXT NOT NULL DEFAULT '#0F766E',
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  business_id   TEXT REFERENCES businesses(id) ON DELETE CASCADE,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name          TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'owner',
  created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS programs (
  id               TEXT PRIMARY KEY,
  business_id      TEXT NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  description      TEXT,
  reward_text      TEXT NOT NULL,
  stamps_required  INTEGER NOT NULL DEFAULT 8,
  cooldown_minutes INTEGER NOT NULL DEFAULT 0,
  max_per_day      INTEGER NOT NULL DEFAULT 0,
  style_json       TEXT NOT NULL,
  active           INTEGER NOT NULL DEFAULT 1,
  created_at       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS customers (
  id         TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
  name       TEXT,
  phone      TEXT,
  email      TEXT,
  consent_at TEXT,
  created_at TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone
  ON customers(business_id, phone) WHERE phone IS NOT NULL AND phone <> '';

CREATE TABLE IF NOT EXISTS cards (
  id          TEXT PRIMARY KEY,
  program_id  TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  code        TEXT NOT NULL UNIQUE,
  stamps      INTEGER NOT NULL DEFAULT 0,
  status      TEXT NOT NULL DEFAULT 'active',
  secret      TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_cards_program ON cards(program_id);

CREATE TABLE IF NOT EXISTS stamps (
  id              TEXT PRIMARY KEY,
  card_id         TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  staff_id        TEXT REFERENCES users(id),
  source          TEXT NOT NULL DEFAULT 'scan',
  idempotency_key TEXT UNIQUE,
  created_at      TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_stamps_card ON stamps(card_id, created_at);

CREATE TABLE IF NOT EXISTS reward_redemptions (
  id              TEXT PRIMARY KEY,
  card_id         TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  staff_id        TEXT REFERENCES users(id),
  reward_text     TEXT,
  idempotency_key TEXT UNIQUE,
  redeemed_at     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS qr_uses (
  token_hash TEXT PRIMARY KEY,
  card_id    TEXT NOT NULL,
  used_at    TEXT NOT NULL
);
`;

function migrate() {
  db.exec(SCHEMA);
}

/** Borra tokens QR viejos para que la tabla no crezca sin limite. */
function cleanupQrUses() {
  const limit = new Date(Date.now() - 10 * 60 * 1000).toISOString();
  db.prepare('DELETE FROM qr_uses WHERE used_at < ?').run(limit);
}

module.exports = { db, migrate, now, id, cleanupQrUses, DB_PATH, DATA_DIR, UPLOAD_DIR };
