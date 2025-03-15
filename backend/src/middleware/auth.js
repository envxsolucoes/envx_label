const jwt = require('jsonwebtoken');

/**
 * Middleware para verificar se o usuário está autenticado
 */
const authenticate = (req, res, next) => {
  try {
    // Obter o token do cabeçalho Authorization
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      const error = new Error('Token de autenticação não fornecido');
      error.name = 'UnauthorizedError';
      throw error;
    }
    
    // Extrair o token
    const token = authHeader.split(' ')[1];
    
    // Verificar e decodificar o token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Adicionar o usuário decodificado à requisição
    req.user = decoded;
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      error.name = 'UnauthorizedError';
      error.message = 'Token inválido ou expirado';
    }
    next(error);
  }
};

/**
 * Middleware para verificar se o usuário tem as permissões necessárias
 * @param {Array} roles - Array de roles permitidas
 */
const authorize = (roles = []) => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        const error = new Error('Usuário não autenticado');
        error.name = 'UnauthorizedError';
        throw error;
      }
      
      // Converter para array se for uma string
      if (typeof roles === 'string') {
        roles = [roles];
      }
      
      // Verificar se o usuário tem pelo menos uma das roles necessárias
      if (roles.length && !roles.includes(req.user.role)) {
        const error = new Error('Permissão negada');
        error.name = 'ForbiddenError';
        throw error;
      }
      
      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = {
  authenticate,
  authorize
}; 