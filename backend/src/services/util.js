const crypto = require('crypto');

const DEFAULT_STYLE = {
  template: 'ticket',
  background: '#0F766E',
  foreground: '#FFFFFF',
  accent: '#F5C451',
  stampIcon: 'circle',
  pattern: 'dots',
  cornerRadius: 24,
  showLogo: true,
};

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function slugify(text) {
  return String(text)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40) || 'negocio';
}

function randomCode(slug, length = 6) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let out = '';
  const bytes = crypto.randomBytes(length);
  for (let i = 0; i < length; i += 1) out += alphabet[bytes[i] % alphabet.length];
  const prefix = slugify(slug).slice(0, 4).toUpperCase().padEnd(3, 'X');
  return `${prefix}-${out}`;
}

function normalizeStyle(input = {}) {
  const style = { ...DEFAULT_STYLE, ...(input || {}) };
  return {
    template: String(style.template),
    background: String(style.background),
    foreground: String(style.foreground),
    accent: String(style.accent),
    stampIcon: String(style.stampIcon),
    pattern: String(style.pattern),
    cornerRadius: Number(style.cornerRadius) || DEFAULT_STYLE.cornerRadius,
    showLogo: Boolean(style.showLogo),
  };
}

function maskName(name) {
  if (!name) return 'Cliente';
  const parts = String(name).trim().split(/\s+/);
  if (parts.length === 1) return parts[0];
  return `${parts[0]} ${parts[1].charAt(0).toUpperCase()}.`;
}

function publicCard({ card, customer, program, business }) {
  return {
    code: card.code,
    stamps: card.stamps,
    stampsRequired: program.stamps_required,
    status: card.status,
    rewardText: program.reward_text,
    createdAt: card.created_at,
    updatedAt: card.updated_at,
    customer: { name: maskName(customer.name) },
    program: {
      id: program.id,
      name: program.name,
      description: program.description,
      style: JSON.parse(program.style_json),
    },
    business: {
      name: business.name,
      slug: business.slug,
      logoUrl: business.logo_url,
      brandColor: business.brand_color,
    },
  };
}

function merchantCard({ card, customer, program }) {
  return {
    id: card.id,
    code: card.code,
    stamps: card.stamps,
    stampsRequired: program.stamps_required,
    status: card.status,
    rewardText: program.reward_text,
    updatedAt: card.updated_at,
    customer: {
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
    },
    programId: program.id,
    programName: program.name,
  };
}

module.exports = {
  DEFAULT_STYLE,
  HttpError,
  slugify,
  randomCode,
  normalizeStyle,
  maskName,
  publicCard,
  merchantCard,
};
