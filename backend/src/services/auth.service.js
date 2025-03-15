const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

/**
 * Serviço para autenticação de usuários
 */
class AuthService {
  /**
   * Autentica um usuário com email e senha
   * @param {string} email - Email do usuário
   * @param {string} password - Senha do usuário
   * @returns {Object} Objeto contendo token e dados do usuário
   */
  async login(email, password) {
    // Buscar usuário pelo email
    const user = await db('users').where({ email }).first();
    
    if (!user) {
      const error = new Error('Credenciais inválidas');
      error.name = 'UnauthorizedError';
      throw error;
    }
    
    // Verificar se a senha está correta
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      const error = new Error('Credenciais inválidas');
      error.name = 'UnauthorizedError';
      throw error;
    }
    
    // Gerar token JWT
    const token = this.generateToken(user);
    
    // Retornar token e dados do usuário (sem a senha)
    const { password: _, ...userWithoutPassword } = user;
    
    return {
      token,
      user: userWithoutPassword
    };
  }
  
  /**
   * Autentica um usuário com GitHub
   * @param {Object} githubUser - Dados do usuário do GitHub
   * @returns {Object} Objeto contendo token e dados do usuário
   */
  async loginWithGithub(githubUser) {
    try {
      // Verificar se o usuário já existe pelo GitHub ID
      let user = await db('users').where({ github_id: githubUser.id }).first();
      
      if (!user) {
        // Verificar se existe um usuário com o mesmo email
        user = await db('users').where({ email: githubUser.email }).first();
        
        if (user) {
          // Atualizar o usuário existente com o GitHub ID
          await db('users')
            .where({ id: user.id })
            .update({ 
              github_id: githubUser.id,
              updated_at: new Date()
            });
        } else {
          // Criar um novo usuário
          const [userId] = await db('users').insert({
            id: uuidv4(),
            name: githubUser.name || githubUser.login,
            email: githubUser.email,
            github_id: githubUser.id,
            role: 'user', // Role padrão
            avatar_url: githubUser.avatar_url,
            created_at: new Date(),
            updated_at: new Date()
          }).returning('id');
          
          user = await db('users').where({ id: userId }).first();
        }
      }
      
      // Gerar token JWT
      const token = this.generateToken(user);
      
      // Retornar token e dados do usuário
      const { password: _, ...userWithoutPassword } = user;
      
      return {
        token,
        user: userWithoutPassword
      };
    } catch (error) {
      console.error('Erro ao autenticar com GitHub:', error);
      throw error;
    }
  }
  
  /**
   * Obtém o token de acesso do GitHub
   * @param {string} code - Código de autorização do GitHub
   * @returns {string} Token de acesso do GitHub
   */
  async getGithubAccessToken(code) {
    try {
      const response = await fetch('https://github.com/login/oauth/access_token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          client_id: process.env.GITHUB_CLIENT_ID,
          client_secret: process.env.GITHUB_CLIENT_SECRET,
          code
        })
      });
      
      const data = await response.json();
      
      if (data.error) {
        throw new Error(data.error_description || 'Erro ao obter token do GitHub');
      }
      
      return data.access_token;
    } catch (error) {
      console.error('Erro ao obter token do GitHub:', error);
      throw error;
    }
  }
  
  /**
   * Obtém os dados do usuário do GitHub
   * @param {string} accessToken - Token de acesso do GitHub
   * @returns {Object} Dados do usuário do GitHub
   */
  async getGithubUser(accessToken) {
    try {
      const response = await fetch('https://api.github.com/user', {
        headers: {
          'Authorization': `token ${accessToken}`
        }
      });
      
      const user = await response.json();
      
      if (user.message) {
        throw new Error(user.message || 'Erro ao obter dados do usuário do GitHub');
      }
      
      // Se o email não estiver disponível, buscar emails do usuário
      if (!user.email) {
        const emailsResponse = await fetch('https://api.github.com/user/emails', {
          headers: {
            'Authorization': `token ${accessToken}`
          }
        });
        
        const emails = await emailsResponse.json();
        
        // Usar o email primário
        const primaryEmail = emails.find(email => email.primary);
        if (primaryEmail) {
          user.email = primaryEmail.email;
        } else if (emails.length > 0) {
          user.email = emails[0].email;
        }
      }
      
      return user;
    } catch (error) {
      console.error('Erro ao obter dados do usuário do GitHub:', error);
      throw error;
    }
  }
  
  /**
   * Gera um token JWT para o usuário
   * @param {Object} user - Dados do usuário
   * @returns {string} Token JWT
   */
  generateToken(user) {
    const payload = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    };
    
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRATION || '24h'
    });
  }
}

module.exports = new AuthService(); 