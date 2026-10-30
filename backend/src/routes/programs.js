const express = require('express');
const { db, id, now } = require('../db');
const { requireAuth } = require('../auth');
const { normalizeStyle } = require('../services/util');

const router = express.Router();
router.use(requireAuth);

const toJson = (row) => ({ ...row, style: JSON.parse(row.style_json), active: Boolean(row.active) });

router.get('/', (req, res) => {
  const rows = db
    .prepare('SELECT * FROM programs WHERE business_id = ? ORDER BY created_at ASC')
    .all(req.user.businessId);
  res.json({ programs: rows.map(toJson) });
});

router.post('/', (req, res) => {
  const { name, description, rewardText, stampsRequired, cooldownMinutes, maxPerDay, style } =
    req.body || {};

  if (!name || String(name).trim().length < 2) {
    return res.status(400).json({ error: 'Poné un nombre para el programa' });
  }
  if (!rewardText || String(rewardText).trim().length < 2) {
    return res.status(400).json({ error: 'Describí la recompensa' });
  }

  const business = db.prepare('SELECT * FROM businesses WHERE id = ?').get(req.user.businessId);
  const normalized = normalizeStyle({ background: business.brand_color, ...(style || {}) });

  const program = {
    id: id(),
    business_id: business.id,
    name: String(name).trim(),
    description: description ? String(description).trim() : null,
    reward_text: String(rewardText).trim(),
    stamps_required: Math.min(30, Math.max(2, Number(stampsRequired) || 8)),
    cooldown_minutes: Math.max(0, Number(cooldownMinutes) || 0),
    max_per_day: Math.max(0, Number(maxPerDay) || 0),
    style_json: JSON.stringify(normalized),
    active: 1,
    created_at: now(),
  };

  db.prepare(
    `INSERT INTO programs
      (id, business_id, name, description, reward_text, stamps_required, cooldown_minutes, max_per_day, style_json, active, created_at)
     VALUES (@id, @business_id, @name, @description, @reward_text, @stamps_required, @cooldown_minutes, @max_per_day, @style_json, @active, @created_at)`,
  ).run(program);

  res.status(201).json({ program: toJson(program) });
});

router.patch('/:id', (req, res) => {
  const current = db
    .prepare('SELECT * FROM programs WHERE id = ? AND business_id = ?')
    .get(req.params.id, req.user.businessId);

  if (!current) return res.status(404).json({ error: 'Programa no encontrado' });

  const body = req.body || {};
  const next = {
    name: body.name ? String(body.name).trim() : current.name,
    description: body.description !== undefined ? String(body.description) : current.description,
    reward_text: body.rewardText ? String(body.rewardText).trim() : current.reward_text,
    stamps_required:
      body.stampsRequired !== undefined
        ? Math.min(30, Math.max(2, Number(body.stampsRequired) || current.stamps_required))
        : current.stamps_required,
    cooldown_minutes:
      body.cooldownMinutes !== undefined
        ? Math.max(0, Number(body.cooldownMinutes) || 0)
        : current.cooldown_minutes,
    max_per_day:
      body.maxPerDay !== undefined
        ? Math.max(0, Number(body.maxPerDay) || 0)
        : current.max_per_day,
    style_json:
      body.style !== undefined
        ? JSON.stringify(normalizeStyle(body.style))
        : current.style_json,
    active: body.active !== undefined ? (body.active ? 1 : 0) : current.active,
  };

  db.prepare(
    `UPDATE programs SET name = @name, description = @description, reward_text = @reward_text,
     stamps_required = @stamps_required, cooldown_minutes = @cooldown_minutes,
     max_per_day = @max_per_day, style_json = @style_json, active = @active
     WHERE id = @id`,
  ).run({ ...next, id: current.id });

  const updated = db.prepare('SELECT * FROM programs WHERE id = ?').get(current.id);
  res.json({ program: toJson(updated) });
});

router.delete('/:id', (req, res) => {
  const current = db
    .prepare('SELECT * FROM programs WHERE id = ? AND business_id = ?')
    .get(req.params.id, req.user.businessId);

  if (!current) return res.status(404).json({ error: 'Programa no encontrado' });

  const { n } = db
    .prepare('SELECT COUNT(*) AS n FROM cards WHERE program_id = ?')
    .get(current.id);

  if (n > 0) {
    return res.status(409).json({
      error: `Este programa tiene ${n} tarjetas activas. Pausalo en vez de borrarlo.`,
    });
  }

  db.prepare('DELETE FROM programs WHERE id = ?').run(current.id);
  res.json({ ok: true });
});

module.exports = { router, toJson };
