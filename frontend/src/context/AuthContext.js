import React, { createContext, useState, useEffect, useContext } from 'react';
import api from '../services/api';

const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const loadStoredData = async () => {
      setLoading(true);
      
      const storedToken = localStorage.getItem('@Rastreabilidade:token');
      const storedUser = localStorage.getItem('@Rastreabilidade:user');
      
      if (storedToken && storedUser) {
        api.defaults.headers.authorization = `Bearer ${storedToken}`;
        
        try {
          // Verificar se o token ainda é válido
          const response = await api.get('/auth/verify');
          
          if (response.data.valid) {
            setUser(JSON.parse(storedUser));
          } else {
            // Token inválido, fazer logout
            localStorage.removeItem('@Rastreabilidade:token');
            localStorage.removeItem('@Rastreabilidade:user');
            api.defaults.headers.authorization = null;
          }
        } catch (err) {
          // Erro ao verificar token, fazer logout
          localStorage.removeItem('@Rastreabilidade:token');
          localStorage.removeItem('@Rastreabilidade:user');
          api.defaults.headers.authorization = null;
        }
      }
      
      setLoading(false);
    };
    
    loadStoredData();
  }, []);

  const login = async (email, password) => {
    try {
      setError(null);
      const response = await api.post('/auth/login', { email, password });
      
      const { token, user } = response.data;
      
      localStorage.setItem('@Rastreabilidade:token', token);
      localStorage.setItem('@Rastreabilidade:user', JSON.stringify(user));
      
      api.defaults.headers.authorization = `Bearer ${token}`;
      
      setUser(user);
      
      return user;
    } catch (err) {
      setError(err.response?.data?.message || 'Erro ao fazer login');
      throw err;
    }
  };

  const loginWithGithub = () => {
    window.location.href = `${process.env.REACT_APP_API_URL}/auth/github`;
  };

  const handleGithubCallback = async (token) => {
    try {
      setError(null);
      
      if (!token) {
        throw new Error('Token não fornecido');
      }
      
      // Configurar o token
      localStorage.setItem('@Rastreabilidade:token', token);
      api.defaults.headers.authorization = `Bearer ${token}`;
      
      // Obter dados do usuário
      const response = await api.get('/auth/verify');
      
      if (response.data.valid) {
        const userData = response.data.user;
        localStorage.setItem('@Rastreabilidade:user', JSON.stringify(userData));
        setUser(userData);
        return userData;
      } else {
        throw new Error('Token inválido');
      }
    } catch (err) {
      setError(err.message || 'Erro ao autenticar com GitHub');
      localStorage.removeItem('@Rastreabilidade:token');
      api.defaults.headers.authorization = null;
      throw err;
    }
  };

  const logout = () => {
    localStorage.removeItem('@Rastreabilidade:token');
    localStorage.removeItem('@Rastreabilidade:user');
    api.defaults.headers.authorization = null;
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        signed: !!user,
        user,
        loading,
        error,
        login,
        loginWithGithub,
        handleGithubCallback,
        logout
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export function useAuth() {
  const context = useContext(AuthContext);
  
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de um AuthProvider');
  }
  
  return context;
}

export default AuthContext; 