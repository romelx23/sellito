const jwt = require('jsonwebtoken');

const SECRET = process.env.JWT_SECRET || 'dev-secret-no-usar-en-produccion';

function sign(user) {
  return jwt.sign(
    { sub: user.id, businessId: user.business_id, role: user.role, email: user.email },
    SECRET,
    { expiresIn: '30d' },
  );
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) return res.status(401).json({ error: 'Falta el token de sesión' });

  try {
    req.user = jwt.verify(token, SECRET);
    return next();
  } catch {
    return res.status(401).json({ error: 'Sesión inválida o expirada' });
  }
}

module.exports = { sign, requireAuth };
