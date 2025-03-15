import React from 'react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import {
  CheckCircleIcon,
  TruckIcon,
  BuildingStorefrontIcon,
  ArchiveBoxIcon,
  ShoppingCartIcon,
} from '@heroicons/react/24/outline';

const Timeline = ({ movements }) => {
  if (!movements || movements.length === 0) {
    return (
      <div className="bg-white shadow rounded-lg p-6 text-center">
        <p className="text-gray-500">Não há dados de rastreabilidade disponíveis.</p>
      </div>
    );
  }

  // Ordenar movimentos por data
  const sortedMovements = [...movements].sort(
    (a, b) => new Date(a.movement_date) - new Date(b.movement_date)
  );

  // Função para obter o ícone com base no tipo de movimento
  const getMovementIcon = (type) => {
    switch (type) {
      case 'production':
        return (
          <CheckCircleIcon className="h-6 w-6 text-green-500" aria-hidden="true" />
        );
      case 'transport':
        return (
          <TruckIcon className="h-6 w-6 text-blue-500" aria-hidden="true" />
        );
      case 'storage':
        return (
          <ArchiveBoxIcon className="h-6 w-6 text-orange-500" aria-hidden="true" />
        );
      case 'distribution':
        return (
          <BuildingStorefrontIcon className="h-6 w-6 text-purple-500" aria-hidden="true" />
        );
      case 'sale':
        return (
          <ShoppingCartIcon className="h-6 w-6 text-red-500" aria-hidden="true" />
        );
      default:
        return (
          <CheckCircleIcon className="h-6 w-6 text-gray-500" aria-hidden="true" />
        );
    }
  };

  // Função para obter a cor da linha com base no tipo de movimento
  const getLineColor = (type) => {
    switch (type) {
      case 'production':
        return 'bg-green-500';
      case 'transport':
        return 'bg-blue-500';
      case 'storage':
        return 'bg-orange-500';
      case 'distribution':
        return 'bg-purple-500';
      case 'sale':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  // Função para formatar a data
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return format(date, "dd 'de' MMMM 'de' yyyy 'às' HH:mm", { locale: ptBR });
  };

  // Função para obter o título do movimento com base no tipo
  const getMovementTitle = (movement) => {
    switch (movement.movement_type) {
      case 'production':
        return `Produção em ${movement.location_name}`;
      case 'transport':
        return `Transporte de ${movement.origin_name || 'Origem'} para ${movement.destination_name || 'Destino'}`;
      case 'storage':
        return `Armazenamento em ${movement.location_name}`;
      case 'distribution':
        return `Distribuição para ${movement.destination_name || 'Destino'}`;
      case 'sale':
        return `Venda para ${movement.destination_name || 'Cliente'}`;
      default:
        return `Movimentação em ${movement.location_name}`;
    }
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-lg font-medium text-gray-900 mb-6">Timeline de Rastreabilidade</h2>
      
      <div className="flow-root">
        <ul className="-mb-8">
          {sortedMovements.map((movement, index) => (
            <li key={movement.id}>
              <div className="relative pb-8">
                {index < sortedMovements.length - 1 ? (
                  <span
                    className="absolute top-4 left-4 -ml-px h-full w-0.5 flex"
                    aria-hidden="true"
                  >
                    <span className={`${getLineColor(movement.movement_type)} w-0.5 flex-1`}></span>
                  </span>
                ) : null}
                
                <div className="relative flex space-x-3">
                  <div>
                    <span className="h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white bg-white">
                      {getMovementIcon(movement.movement_type)}
                    </span>
                  </div>
                  
                  <div className="min-w-0 flex-1 pt-1.5 flex justify-between space-x-4">
                    <div>
                      <p className="text-sm text-gray-900 font-medium">
                        {getMovementTitle(movement)}
                      </p>
                      
                      {movement.additional_info && (
                        <p className="mt-1 text-sm text-gray-500">
                          {movement.additional_info}
                        </p>
                      )}
                      
                      <div className="mt-1 flex items-center text-sm text-gray-500">
                        <span className="truncate">
                          Quantidade: {movement.quantity} {movement.unit}
                        </span>
                      </div>
                    </div>
                    
                    <div className="text-right text-sm whitespace-nowrap text-gray-500">
                      <time dateTime={movement.movement_date}>
                        {formatDate(movement.movement_date)}
                      </time>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default Timeline; 