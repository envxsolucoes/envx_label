import React, { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import { toast } from 'react-hot-toast';
import api from '../../services/api';

const QRCodeGenerator = ({ batch }) => {
  const [loading, setLoading] = useState(false);
  const [qrCodeData, setQRCodeData] = useState(batch?.qr_code || null);
  const [size, setSize] = useState(200);
  
  // URL para consulta pública
  const publicUrl = `${window.location.origin}/public/trace/${batch?.batch_number}`;
  
  // Gerar QR Code
  const generateQRCode = async () => {
    try {
      setLoading(true);
      
      // Se já existe um QR Code, apenas exibir
      if (batch?.qr_code) {
        setQRCodeData(batch.qr_code);
        setLoading(false);
        return;
      }
      
      // Caso contrário, gerar um novo
      const response = await api.post(`/batches/${batch.id}/qrcode`);
      
      setQRCodeData(response.data.qr_code);
      toast.success('QR Code gerado com sucesso!');
      setLoading(false);
    } catch (error) {
      console.error('Erro ao gerar QR Code:', error);
      toast.error('Erro ao gerar QR Code');
      setLoading(false);
    }
  };
  
  // Baixar QR Code como PNG
  const downloadQRCode = () => {
    const canvas = document.getElementById('qr-code-canvas');
    if (!canvas) return;
    
    const pngUrl = canvas
      .toDataURL('image/png')
      .replace('image/png', 'image/octet-stream');
    
    const downloadLink = document.createElement('a');
    downloadLink.href = pngUrl;
    downloadLink.download = `qrcode-${batch.batch_number}.png`;
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
  };
  
  // Copiar URL para a área de transferência
  const copyUrlToClipboard = () => {
    navigator.clipboard.writeText(publicUrl)
      .then(() => {
        toast.success('URL copiada para a área de transferência!');
      })
      .catch((error) => {
        console.error('Erro ao copiar URL:', error);
        toast.error('Erro ao copiar URL');
      });
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-lg font-medium text-gray-900 mb-4">QR Code de Rastreabilidade</h2>
      
      <div className="space-y-6">
        {/* QR Code */}
        <div className="flex flex-col items-center">
          {qrCodeData ? (
            <div className="border p-4 rounded-lg bg-white">
              <QRCodeSVG
                id="qr-code"
                value={qrCodeData}
                size={size}
                level="H"
                includeMargin={true}
                imageSettings={{
                  src: '/logo.png',
                  x: undefined,
                  y: undefined,
                  height: 24,
                  width: 24,
                  excavate: true,
                }}
              />
              <canvas
                id="qr-code-canvas"
                style={{ display: 'none' }}
              />
            </div>
          ) : (
            <div className="border p-4 rounded-lg bg-gray-50 flex items-center justify-center" style={{ width: size, height: size }}>
              <p className="text-gray-500 text-center">
                Clique em "Gerar QR Code" para criar um código de rastreabilidade
              </p>
            </div>
          )}
          
          {/* Controle de tamanho */}
          <div className="mt-4 w-full max-w-xs">
            <label htmlFor="size" className="block text-sm font-medium text-gray-700">
              Tamanho: {size}px
            </label>
            <input
              type="range"
              id="size"
              min="100"
              max="400"
              step="10"
              value={size}
              onChange={(e) => setSize(Number(e.target.value))}
              className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer"
            />
          </div>
        </div>
        
        {/* URL de consulta pública */}
        <div className="mt-4">
          <label htmlFor="public-url" className="block text-sm font-medium text-gray-700">
            URL de Consulta Pública
          </label>
          <div className="mt-1 flex rounded-md shadow-sm">
            <input
              type="text"
              id="public-url"
              className="flex-1 min-w-0 block w-full px-3 py-2 rounded-none rounded-l-md border-gray-300 focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              value={publicUrl}
              readOnly
            />
            <button
              type="button"
              onClick={copyUrlToClipboard}
              className="inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 rounded-r-md bg-gray-50 text-gray-500 sm:text-sm hover:bg-gray-100"
            >
              Copiar
            </button>
          </div>
        </div>
        
        {/* Botões */}
        <div className="flex flex-col sm:flex-row sm:justify-between space-y-3 sm:space-y-0 sm:space-x-3">
          <button
            type="button"
            onClick={generateQRCode}
            disabled={loading}
            className="inline-flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            {loading ? 'Gerando...' : qrCodeData ? 'Atualizar QR Code' : 'Gerar QR Code'}
          </button>
          
          {qrCodeData && (
            <button
              type="button"
              onClick={downloadQRCode}
              className="inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              Baixar QR Code
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default QRCodeGenerator; 