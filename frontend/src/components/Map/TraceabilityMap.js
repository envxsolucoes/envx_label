import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Corrigir o problema dos ícones do Leaflet
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

let DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

L.Marker.prototype.options.icon = DefaultIcon;

const TraceabilityMap = ({ movements }) => {
  // Calcular o centro do mapa com base nos movimentos
  const calculateCenter = () => {
    if (!movements || movements.length === 0) {
      return [-15.7801, -47.9292]; // Centro do Brasil (Brasília)
    }

    const latitudes = movements.map(m => m.latitude).filter(Boolean);
    const longitudes = movements.map(m => m.longitude).filter(Boolean);

    if (latitudes.length === 0 || longitudes.length === 0) {
      return [-15.7801, -47.9292]; // Centro do Brasil (Brasília)
    }

    const avgLat = latitudes.reduce((sum, lat) => sum + lat, 0) / latitudes.length;
    const avgLng = longitudes.reduce((sum, lng) => sum + lng, 0) / longitudes.length;

    return [avgLat, avgLng];
  };

  // Criar linha de conexão entre os pontos
  const createPolyline = () => {
    if (!movements || movements.length < 2) {
      return null;
    }

    const points = movements
      .filter(m => m.latitude && m.longitude)
      .map(m => [m.latitude, m.longitude]);

    if (points.length < 2) {
      return null;
    }

    return (
      <Polyline
        positions={points}
        color="#0ea5e9"
        weight={3}
        opacity={0.7}
        dashArray="5, 10"
      />
    );
  };

  // Cores para os diferentes tipos de movimento
  const getMarkerColor = (movementType) => {
    switch (movementType) {
      case 'production':
        return 'green';
      case 'transport':
        return 'blue';
      case 'storage':
        return 'orange';
      case 'distribution':
        return 'purple';
      case 'sale':
        return 'red';
      default:
        return 'gray';
    }
  };

  // Criar ícone personalizado com base no tipo de movimento
  const createCustomIcon = (movementType) => {
    const color = getMarkerColor(movementType);
    
    return L.divIcon({
      className: 'custom-marker',
      html: `<div style="background-color: ${color}; width: 12px; height: 12px; border-radius: 50%; border: 2px solid white;"></div>`,
      iconSize: [16, 16],
      iconAnchor: [8, 8],
    });
  };

  if (!movements || movements.length === 0) {
    return (
      <div className="bg-gray-100 rounded-lg p-4 text-center">
        <p className="text-gray-500">Não há dados de localização disponíveis.</p>
      </div>
    );
  }

  return (
    <MapContainer center={calculateCenter()} zoom={5} style={{ height: '400px', width: '100%' }}>
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      
      {movements
        .filter(m => m.latitude && m.longitude)
        .map((movement, index) => (
          <Marker
            key={index}
            position={[movement.latitude, movement.longitude]}
            icon={createCustomIcon(movement.movement_type)}
          >
            <Popup>
              <div>
                <h3 className="font-semibold">{movement.location_name}</h3>
                <p className="text-sm">Tipo: {movement.movement_type}</p>
                <p className="text-sm">Data: {new Date(movement.movement_date).toLocaleDateString()}</p>
                {movement.additional_info && (
                  <p className="text-sm">{movement.additional_info}</p>
                )}
              </div>
            </Popup>
          </Marker>
        ))}
      
      {createPolyline()}
    </MapContainer>
  );
};

export default TraceabilityMap; 