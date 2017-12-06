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
        p_attributes = attributes

        p_attributes.delete("avatar_file_name")
        p_attributes.delete("avatar_content_type")
        p_attributes.delete("avatar_file_size")
        p_attributes.delete("avatar_updated_at")

        si_response = ManageSIModelService.new(si_class_name, @token, p_attributes).check

        # return true if si_response.status_code == 500
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
                                     
        processed_attributes.delete("avatar_file_name")
        processed_attributes.delete("avatar_content_type")
        processed_attributes.delete("avatar_file_size")
        processed_attributes.delete("avatar_updated_at")

        if si_class_name == 'Commute'
          processed_attributes = processed_attributes.merge(detours: self.detours.map(&:id), stations: self.stations.map(&:id))

          # raise processed_attributes.inspect
          if  processed_attributes['time']
            processed_attributes['time'] = processed_attributes['time'].utc.strftime("%H:%M")
          else
            processed_attributes['time'] = ""
          end
        end

        if valid?
          si_response = ManageSIModelService.new(si_class_name, @token, processed_attributes).put

          return si_response.results.inspect

          if si_response && si_response.response_object && si_response.response_object['results'] && si_response.response_object['results']['id']
            return si_response.response_object['results']['id']
          else
            return true
          end
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
