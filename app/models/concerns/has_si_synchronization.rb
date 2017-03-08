module Concerns
  module HasSiSynchronization
    extend ActiveSupport::Concern

    included do
      def self.create(attribute)
        raise 'create not yet implemented'
      end

      def self.create!(attributes)
        create(attributes)
      end

      def delete
        si_response = ManageSIModelService.new(si_class_name, @token, attributes).del
        return true
      end

      def destroy
        delete
      end

      def destroy!
        delete
      end

      def delete!
        delete
      end

      def update
        raise 'update not yet implemented'
      end

      def update!
        update
      end

      def errors
        @errors ||= nil
      end

      def valid?
        si_response = ManageSIModelService.new(si_class_name, @token, attributes).check

        si_results  = si_response.response_object['results']
        validity    = si_results['validity']
        @errors     = validity ? nil : si_results["errors"] 

        return validity
      end

      def authenticate(token)
        @token = token
      end

      def save!
        save
      end

      def save
        # self.id = new_id unless self.id

        processed_attributes = attributes

        if si_class_name == 'Commute'
          if  processed_attributes['time']
            processed_attributes['time'] = processed_attributes['time'].utc.strftime("%H:%M")
          else
            processed_attributes['time'] = ""
          end
        end

        if valid?
          
          si_response = ManageSIModelService.new(si_class_name, @token, processed_attributes).put

          return true
        else
          # self.id = nil
          return false
        end
      end

      def si_class_name
        self.class.name.split('::').last
      end

      def readonly?
        true
      end

      def last_id
        self.class.last.id
      end

      def new_id
        last_id + 1
      end
    end
  end
end
