const express = require('express');
const { get, all, run, id, now } = require('../db');
const { requireAuth } = require('../auth');
const { normalizeStyle } = require('../services/util');

const router = express.Router();
router.use(requireAuth);

const toJson = (row) => ({ ...row, style: JSON.parse(row.style_json), active: Boolean(row.active) });

router.get('/', async (req, res, next) => {
  try {
    const rows = await all('SELECT * FROM programs WHERE business_id = ? ORDER BY created_at ASC', [
      req.user.businessId,
    ]);
    res.json({ programs: rows.map(toJson) });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const { name, description, rewardText, stampsRequired, cooldownMinutes, maxPerDay, style } =
      req.body || {};

    if (!name || String(name).trim().length < 2) {
      return res.status(400).json({ error: 'Poné un nombre para el programa' });
    }
    if (!rewardText || String(rewardText).trim().length < 2) {
      return res.status(400).json({ error: 'Describí la recompensa' });
    }

    const business = await get('SELECT * FROM businesses WHERE id = ?', [req.user.businessId]);
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

    await run(
      `INSERT INTO programs
        (id, business_id, name, description, reward_text, stamps_required, cooldown_minutes, max_per_day, style_json, active, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        program.id,
        program.business_id,
        program.name,
        program.description,
        program.reward_text,
        program.stamps_required,
        program.cooldown_minutes,
        program.max_per_day,
        program.style_json,
        program.active,
        program.created_at,
      ],
    );

    res.status(201).json({ program: toJson(program) });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id', async (req, res, next) => {
  try {
    const current = await get('SELECT * FROM programs WHERE id = ? AND business_id = ?', [
      req.params.id,
      req.user.businessId,
    ]);

    if (!current) return res.status(404).json({ error: 'Programa no encontrado' });

    const body = req.body || {};
    const nextValues = {
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

    await run(
      `UPDATE programs SET name = ?, description = ?, reward_text = ?,
       stamps_required = ?, cooldown_minutes = ?, max_per_day = ?, style_json = ?, active = ?
       WHERE id = ?`,
      [
        nextValues.name,
        nextValues.description,
        nextValues.reward_text,
        nextValues.stamps_required,
        nextValues.cooldown_minutes,
        nextValues.max_per_day,
        nextValues.style_json,
        nextValues.active,
        current.id,
      ],
    );

    const updated = await get('SELECT * FROM programs WHERE id = ?', [current.id]);
    res.json({ program: toJson(updated) });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const current = await get('SELECT * FROM programs WHERE id = ? AND business_id = ?', [
      req.params.id,
      req.user.businessId,
    ]);

    if (!current) return res.status(404).json({ error: 'Programa no encontrado' });

    const { n } = await get('SELECT COUNT(*) AS n FROM cards WHERE program_id = ?', [current.id]);

    if (n > 0) {
      return res.status(409).json({
        error: `Este programa tiene ${n} tarjetas activas. Pausalo en vez de borrarlo.`,
      });
    }

    await run('DELETE FROM programs WHERE id = ?', [current.id]);
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

module.exports = { router, toJson };
