import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';

const GithubCallback = () => {
  const { handleGithubCallback } = useAuth();
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const processCallback = async () => {
      try {
        // Obter o token da URL
        const params = new URLSearchParams(location.search);
        const token = params.get('token');
        
        if (!token) {
          throw new Error('Token não encontrado na URL');
        }
        
        // Processar o callback
        await handleGithubCallback(token);
        
        // Redirecionar para a página inicial
        navigate('/');
      } catch (err) {
        console.error('Erro ao processar callback do GitHub:', err);
        setError(err.message || 'Erro ao autenticar com GitHub');
        // Redirecionar para a página de login após 3 segundos
        setTimeout(() => {
          navigate('/login');
        }, 3000);
      } finally {
        setLoading(false);
      }
    };
    
    processCallback();
  }, [handleGithubCallback, location.search, navigate]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="max-w-md w-full space-y-8 text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500 mx-auto"></div>
          <h2 className="text-xl font-medium text-gray-900">
            Autenticando com GitHub...
          </h2>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="max-w-md w-full space-y-8 text-center">
          <div className="rounded-md bg-red-50 p-4">
            <h2 className="text-lg font-medium text-red-800">
              Erro ao autenticar com GitHub
            </h2>
            <p className="mt-2 text-sm text-red-700">{error}</p>
            <p className="mt-2 text-sm text-gray-500">
              Redirecionando para a página de login...
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 text-center">
        <h2 className="text-xl font-medium text-gray-900">
          Autenticação bem-sucedida!
        </h2>
        <p className="text-sm text-gray-500">
          Redirecionando...
        </p>
      </div>
    </div>
  );
};

export default GithubCallback; 