module Concerns
  module HasNonPersistantSynchronizationWithSiModel
    extend ActiveSupport::Concern

    included do
      attr_accessor :si_attributes

      SYNCHRONISABLE_CLASSES = ['Web::Trip', 'Web::Commute', 'Web::DbCommute']
      JOIN_TABLE_FIELDS      = [:location, :destination]

      def rpc_client
        @rpc_client ||= WebEngine::RpcClient.new
      end

      def get_from_si
        raise "Class #{self.class.name} is not supported for synchronization" unless SYNCHRONISABLE_CLASSES.include?(self.class.name)

        validate_si_mandatory_fields
        WebEngine::SiClient.initialize_connection

        # rpc_client = WebEngine::RpcClient.new
        si_entity  = self.class.name.split('::').last.downcase

        processed_attributes = {}

        self.class::SI_MANDATORY_FIELDS.each do |mandatory_field|
          processed_attributes[field_name_or_field_id(mandatory_field)] = field_id_or_field_value(mandatory_field)
        end

        result = rpc_client.send("get_#{si_entity}", processed_attributes)  

        if result && result.response_object
          self.si_attributes = result.response_object
          map_si_attributes_to_model_fields
        end
      end

      def validate_si_mandatory_fields
        missing_fields = [] 
        self.class::SI_MANDATORY_FIELDS.each do |mandatory_field|
          missing_fields << mandatory_field unless self.send(mandatory_field)
        end

        raise "Missing fiel(s): #{missing_fields.map(&:to_s).join(', ')} to get data from SI." if missing_fields.any?
      end

      def map_si_attributes_to_model_fields
        self.class::SI_FIELDS_MAPPING.each do |origin_field, destination_field|
          self.send("#{destination_field.to_s}=", self.si_attributes[origin_field.to_s])
        end
      end

      def field_name_or_field_id(field_name)
        JOIN_TABLE_FIELDS.include?(field_name) ? "#{field_name}_id".to_sym : field_name.to_sym
      end

      def field_id_or_field_value(field_name)
        JOIN_TABLE_FIELDS.include?(field_name) ? self.send(field_name).id : self.send(field_name)
      end

      # def save_to_si
      # end
    end
  end
end
