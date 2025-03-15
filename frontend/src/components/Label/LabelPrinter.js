import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { toast } from 'react-hot-toast';
import api from '../../services/api';

const LabelPrinter = ({ batch, labelTemplates }) => {
  const [loading, setLoading] = useState(false);
  const [previewUrl, setPreviewUrl] = useState(null);
  
  const { 
    register, 
    handleSubmit, 
    watch,
    formState: { errors } 
  } = useForm({
    defaultValues: {
      label_template_id: '',
      quantity: 1,
      printer_ip: localStorage.getItem('printer_ip') || '',
      printer_port: localStorage.getItem('printer_port') || '9100',
    }
  });
  
  const selectedTemplateId = watch('label_template_id');
  const selectedTemplate = labelTemplates?.find(t => t.id === selectedTemplateId);

  // Gerar preview da etiqueta
  const generatePreview = async (data) => {
    try {
      setLoading(true);
      
      const response = await api.post('/labels/preview', {
        batch_id: batch.id,
        label_template_id: data.label_template_id,
      });
      
      setPreviewUrl(response.data.preview_url);
      setLoading(false);
    } catch (error) {
      console.error('Erro ao gerar preview:', error);
      toast.error('Erro ao gerar preview da etiqueta');
      setLoading(false);
    }
  };

  // Imprimir etiqueta
  const onSubmit = async (data) => {
    try {
      setLoading(true);
      
      // Salvar configurações da impressora no localStorage
      localStorage.setItem('printer_ip', data.printer_ip);
      localStorage.setItem('printer_port', data.printer_port);
      
      const response = await api.post('/labels/print', {
        batch_id: batch.id,
        label_template_id: data.label_template_id,
        quantity: parseInt(data.quantity),
        printer_ip: data.printer_ip,
        printer_port: parseInt(data.printer_port),
      });
      
      toast.success('Etiqueta enviada para impressão com sucesso!');
      setLoading(false);
    } catch (error) {
      console.error('Erro ao imprimir etiqueta:', error);
      toast.error('Erro ao imprimir etiqueta');
      setLoading(false);
    }
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-lg font-medium text-gray-900 mb-4">Impressão de Etiquetas</h2>
      
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {/* Modelo de Etiqueta */}
        <div>
          <label htmlFor="label_template_id" className="block text-sm font-medium text-gray-700">
            Modelo de Etiqueta
          </label>
          <select
            id="label_template_id"
            className={`mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md ${
              errors.label_template_id ? 'border-red-300' : ''
            }`}
            {...register('label_template_id', { required: 'Selecione um modelo de etiqueta' })}
          >
            <option value="">Selecione um modelo</option>
            {labelTemplates?.map((template) => (
              <option key={template.id} value={template.id}>
                {template.name} ({template.width}x{template.height} {template.unit})
              </option>
            ))}
          </select>
          {errors.label_template_id && (
            <p className="mt-1 text-sm text-red-600">{errors.label_template_id.message}</p>
          )}
        </div>
        
        {/* Quantidade */}
        <div>
          <label htmlFor="quantity" className="block text-sm font-medium text-gray-700">
            Quantidade
          </label>
          <input
            type="number"
            id="quantity"
            min="1"
            max="100"
            className={`mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500 sm:text-sm ${
              errors.quantity ? 'border-red-300' : ''
            }`}
            {...register('quantity', { 
              required: 'Quantidade é obrigatória',
              min: { value: 1, message: 'Quantidade mínima é 1' },
              max: { value: 100, message: 'Quantidade máxima é 100' }
            })}
          />
          {errors.quantity && (
            <p className="mt-1 text-sm text-red-600">{errors.quantity.message}</p>
          )}
        </div>
        
        {/* Configurações da Impressora */}
        <div className="bg-gray-50 p-4 rounded-md">
          <h3 className="text-sm font-medium text-gray-700 mb-3">Configurações da Impressora</h3>
          
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {/* IP da Impressora */}
            <div>
              <label htmlFor="printer_ip" className="block text-sm font-medium text-gray-700">
                IP da Impressora
              </label>
              <input
                type="text"
                id="printer_ip"
                placeholder="192.168.1.100"
                className={`mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500 sm:text-sm ${
                  errors.printer_ip ? 'border-red-300' : ''
                }`}
                {...register('printer_ip', { 
                  required: 'IP da impressora é obrigatório',
                  pattern: {
                    value: /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/,
                    message: 'IP inválido'
                  }
                })}
              />
              {errors.printer_ip && (
                <p className="mt-1 text-sm text-red-600">{errors.printer_ip.message}</p>
              )}
            </div>
            
            {/* Porta da Impressora */}
            <div>
              <label htmlFor="printer_port" className="block text-sm font-medium text-gray-700">
                Porta
              </label>
              <input
                type="text"
                id="printer_port"
                placeholder="9100"
                className={`mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-primary-500 focus:border-primary-500 sm:text-sm ${
                  errors.printer_port ? 'border-red-300' : ''
                }`}
                {...register('printer_port', { 
                  required: 'Porta da impressora é obrigatória',
                  pattern: {
                    value: /^[0-9]+$/,
                    message: 'Porta inválida'
                  }
                })}
              />
              {errors.printer_port && (
                <p className="mt-1 text-sm text-red-600">{errors.printer_port.message}</p>
              )}
            </div>
          </div>
        </div>
        
        {/* Preview e Botões */}
        <div className="flex flex-col space-y-4">
          {/* Preview */}
          {selectedTemplateId && (
            <button
              type="button"
              onClick={() => generatePreview({ label_template_id: selectedTemplateId })}
              className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              disabled={loading || !selectedTemplateId}
            >
              {loading ? 'Gerando...' : 'Gerar Preview'}
            </button>
          )}
          
          {/* Exibir Preview */}
          {previewUrl && (
            <div className="mt-4 border rounded-md p-2">
              <img 
                src={previewUrl} 
                alt="Preview da Etiqueta" 
                className="max-w-full h-auto mx-auto"
              />
            </div>
          )}
          
          {/* Botão de Impressão */}
          <div className="flex justify-end">
            <button
              type="submit"
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              disabled={loading}
            >
              {loading ? 'Imprimindo...' : 'Imprimir Etiqueta'}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
};

export default LabelPrinter; 