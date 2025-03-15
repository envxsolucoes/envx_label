const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');

// Rota de login com email e senha
router.post('/login', authController.login);

// Rotas de autenticação com GitHub
router.get('/github', authController.githubAuth);
router.get('/github/callback', authController.githubCallback);

// Rota para verificar se o token é válido
router.get('/verify', authenticate, authController.verifyToken);

module.exports = router; 