const authService = require('../services/auth.service');

/**
 * Controlador para autenticação de usuários
 */
class AuthController {
  /**
   * Login com email e senha
   * @param {Object} req - Requisição Express
   * @param {Object} res - Resposta Express
   * @param {Function} next - Próximo middleware
   */
  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      
      if (!email || !password) {
        const error = new Error('Email e senha são obrigatórios');
        error.name = 'ValidationError';
        throw error;
      }
      
      const result = await authService.login(email, password);
      
      res.json(result);
    } catch (error) {
      next(error);
    }
  }
  
  /**
   * Redireciona para autenticação do GitHub
   * @param {Object} req - Requisição Express
   * @param {Object} res - Resposta Express
   */
  githubAuth(req, res) {
    const githubAuthUrl = `https://github.com/login/oauth/authorize?client_id=${process.env.GITHUB_CLIENT_ID}&redirect_uri=${process.env.GITHUB_CALLBACK_URL}&scope=user:email`;
    res.redirect(githubAuthUrl);
  }
  
  /**
   * Callback para autenticação do GitHub
   * @param {Object} req - Requisição Express
   * @param {Object} res - Resposta Express
   * @param {Function} next - Próximo middleware
   */
  async githubCallback(req, res, next) {
    try {
      const { code } = req.query;
      
      if (!code) {
        return res.redirect('/login?error=github_auth_failed');
      }
      
      // Obter token de acesso do GitHub
      const accessToken = await authService.getGithubAccessToken(code);
      
      // Obter dados do usuário do GitHub
      const githubUser = await authService.getGithubUser(accessToken);
      
      // Autenticar ou criar usuário
      const result = await authService.loginWithGithub(githubUser);
      
      // Redirecionar para o frontend com o token
      res.redirect(`${process.env.FRONTEND_URL}/auth/callback?token=${result.token}`);
    } catch (error) {
      console.error('Erro no callback do GitHub:', error);
      res.redirect('/login?error=github_auth_failed');
    }
  }
  
  /**
   * Verifica se o token é válido
   * @param {Object} req - Requisição Express
   * @param {Object} res - Resposta Express
   */
  verifyToken(req, res) {
    // Se chegou aqui, o token é válido (verificado pelo middleware de autenticação)
    res.json({
      valid: true,
      user: req.user
    });
  }
}

module.exports = new AuthController(); 