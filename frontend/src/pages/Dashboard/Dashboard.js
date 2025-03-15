import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from 'chart.js';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import { useAuth } from '../../context/AuthContext';
import api from '../../services/api';

// Registrar componentes do Chart.js
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
);

const Dashboard = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalProducts: 0,
    totalCompanies: 0,
    totalBatches: 0,
    totalMovements: 0,
    recentBatches: [],
    recentMovements: [],
    productionByMonth: {
      labels: [],
      data: [],
    },
    batchesByStatus: {
      labels: [],
      data: [],
    },
    movementsByType: {
      labels: [],
      data: [],
    },
  });

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        
        // Em um cenário real, você buscaria esses dados da API
        // const response = await api.get('/reports/dashboard');
        // setStats(response.data);
        
        // Dados simulados para demonstração
        setStats({
          totalProducts: 24,
          totalCompanies: 8,
          totalBatches: 156,
          totalMovements: 342,
          recentBatches: [
            { id: '1', batch_number: 'LOTE-001', product_name: 'Maçã Gala', quantity: 500, unit: 'kg', production_date: '2023-11-15' },
            { id: '2', batch_number: 'LOTE-002', product_name: 'Laranja Pera', quantity: 800, unit: 'kg', production_date: '2023-11-16' },
            { id: '3', batch_number: 'LOTE-003', product_name: 'Uva Niágara', quantity: 300, unit: 'kg', production_date: '2023-11-17' },
            { id: '4', batch_number: 'LOTE-004', product_name: 'Banana Prata', quantity: 600, unit: 'kg', production_date: '2023-11-18' },
          ],
          recentMovements: [
            { id: '1', batch_number: 'LOTE-001', origin: 'Fazenda São João', destination: 'Distribuidor Central', quantity: 500, unit: 'kg', date: '2023-11-16' },
            { id: '2', batch_number: 'LOTE-002', origin: 'Fazenda Boa Vista', destination: 'Distribuidor Central', quantity: 800, unit: 'kg', date: '2023-11-17' },
            { id: '3', batch_number: 'LOTE-001', origin: 'Distribuidor Central', destination: 'Supermercado ABC', quantity: 200, unit: 'kg', date: '2023-11-18' },
            { id: '4', batch_number: 'LOTE-003', origin: 'Fazenda Santa Clara', destination: 'Distribuidor Central', quantity: 300, unit: 'kg', date: '2023-11-19' },
          ],
          productionByMonth: {
            labels: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
            data: [120, 150, 180, 220, 250, 300, 280, 260, 300, 340, 380, 400],
          },
          batchesByStatus: {
            labels: ['Produção', 'Em Trânsito', 'Distribuição', 'Varejo', 'Consumido'],
            data: [30, 25, 40, 50, 11],
          },
          movementsByType: {
            labels: ['Produção', 'Transporte', 'Armazenamento', 'Distribuição', 'Venda'],
            data: [35, 25, 15, 15, 10],
          },
        });
        
        setLoading(false);
      } catch (error) {
        console.error('Erro ao buscar dados do dashboard:', error);
        setLoading(false);
      }
    };
    
    fetchDashboardData();
  }, []);

  // Configuração dos gráficos
  const lineChartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Produção Mensal (kg)',
      },
    },
  };

  const lineChartData = {
    labels: stats.productionByMonth.labels,
    datasets: [
      {
        label: 'Produção',
        data: stats.productionByMonth.data,
        borderColor: 'rgb(14, 165, 233)',
        backgroundColor: 'rgba(14, 165, 233, 0.5)',
      },
    ],
  };

  const doughnutChartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Lotes por Status',
      },
    },
  };

  const doughnutChartData = {
    labels: stats.batchesByStatus.labels,
    datasets: [
      {
        label: 'Lotes',
        data: stats.batchesByStatus.data,
        backgroundColor: [
          'rgba(14, 165, 233, 0.7)',
          'rgba(20, 184, 166, 0.7)',
          'rgba(245, 158, 11, 0.7)',
          'rgba(139, 92, 246, 0.7)',
          'rgba(239, 68, 68, 0.7)',
        ],
        borderColor: [
          'rgb(14, 165, 233)',
          'rgb(20, 184, 166)',
          'rgb(245, 158, 11)',
          'rgb(139, 92, 246)',
          'rgb(239, 68, 68)',
        ],
        borderWidth: 1,
      },
    ],
  };

  const barChartOptions = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Movimentações por Tipo',
      },
    },
  };

  const barChartData = {
    labels: stats.movementsByType.labels,
    datasets: [
      {
        label: 'Movimentações',
        data: stats.movementsByType.data,
        backgroundColor: 'rgba(20, 184, 166, 0.7)',
      },
    ],
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Bem-vindo, {user?.name}! Aqui está um resumo do sistema de rastreabilidade.
        </p>
      </div>

      {/* Cards de estatísticas */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <dt className="text-sm font-medium text-gray-500 truncate">Total de Produtos</dt>
            <dd className="mt-1 text-3xl font-semibold text-gray-900">{stats.totalProducts}</dd>
          </div>
          <div className="bg-gray-50 px-4 py-3">
            <Link to="/products" className="text-sm font-medium text-primary-600 hover:text-primary-500">
              Ver todos os produtos
            </Link>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <dt className="text-sm font-medium text-gray-500 truncate">Total de Empresas</dt>
            <dd className="mt-1 text-3xl font-semibold text-gray-900">{stats.totalCompanies}</dd>
          </div>
          <div className="bg-gray-50 px-4 py-3">
            <Link to="/companies" className="text-sm font-medium text-primary-600 hover:text-primary-500">
              Ver todas as empresas
            </Link>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <dt className="text-sm font-medium text-gray-500 truncate">Total de Lotes</dt>
            <dd className="mt-1 text-3xl font-semibold text-gray-900">{stats.totalBatches}</dd>
          </div>
          <div className="bg-gray-50 px-4 py-3">
            <Link to="/batches" className="text-sm font-medium text-primary-600 hover:text-primary-500">
              Ver todos os lotes
            </Link>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <dt className="text-sm font-medium text-gray-500 truncate">Total de Movimentações</dt>
            <dd className="mt-1 text-3xl font-semibold text-gray-900">{stats.totalMovements}</dd>
          </div>
          <div className="bg-gray-50 px-4 py-3">
            <Link to="/traceability" className="text-sm font-medium text-primary-600 hover:text-primary-500">
              Ver rastreabilidade
            </Link>
          </div>
        </div>
      </div>

      {/* Gráficos */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <Line options={lineChartOptions} data={lineChartData} />
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <Doughnut options={doughnutChartOptions} data={doughnutChartData} />
          </div>
        </div>
      </div>

      <div className="bg-white overflow-hidden shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <Bar options={barChartOptions} data={barChartData} />
        </div>
      </div>

      {/* Tabelas */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
        {/* Lotes Recentes */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">Lotes Recentes</h3>
            <div className="mt-4 flow-root">
              <div className="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div className="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table className="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">
                          Lote
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Produto
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Quantidade
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Data
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {stats.recentBatches.map((batch) => (
                        <tr key={batch.id}>
                          <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                            <Link to={`/batches/${batch.id}`} className="text-primary-600 hover:text-primary-900">
                              {batch.batch_number}
                            </Link>
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{batch.product_name}</td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {batch.quantity} {batch.unit}
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {new Date(batch.production_date).toLocaleDateString()}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            <div className="mt-4">
              <Link to="/batches" className="text-sm font-medium text-primary-600 hover:text-primary-500">
                Ver todos os lotes
              </Link>
            </div>
          </div>
        </div>

        {/* Movimentações Recentes */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">Movimentações Recentes</h3>
            <div className="mt-4 flow-root">
              <div className="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                <div className="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                  <table className="min-w-full divide-y divide-gray-300">
                    <thead>
                      <tr>
                        <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">
                          Lote
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Origem
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Destino
                        </th>
                        <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                          Data
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-200">
                      {stats.recentMovements.map((movement) => (
                        <tr key={movement.id}>
                          <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                            <Link to={`/batches/${movement.id}`} className="text-primary-600 hover:text-primary-900">
                              {movement.batch_number}
                            </Link>
                          </td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{movement.origin}</td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{movement.destination}</td>
                          <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                            {new Date(movement.date).toLocaleDateString()}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
            <div className="mt-4">
              <Link to="/traceability" className="text-sm font-medium text-primary-600 hover:text-primary-500">
                Ver todas as movimentações
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 