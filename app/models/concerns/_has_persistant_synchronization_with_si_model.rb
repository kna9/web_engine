module Concerns
  module HasPersistantSynchronizationWithSiModel
    extend ActiveSupport::Concern

    included do
      def self.get_all_from_si
        puts '---------get_all_from_si---------'
        puts self.all.count.inspect
        puts '---------------------------------'
      end

      def self.save_all_to_si
        puts '---------save_all_to_si----------'
        puts self.all.count.inspect
        puts '---------------------------------'
      end

      def get_from_si
        puts '---------get_from_si-------------'
        puts self.attributes.inspect
        puts self.si_attributes
        puts '---------------------------------'
      end

      def save_to_si
        puts '---------save_to_si--------------'
        puts self.attributes.inspect
        puts self.si_attributes
        puts '---------------------------------'
      end
    end
  end
end
