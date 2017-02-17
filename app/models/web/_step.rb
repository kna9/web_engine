module Web
  class Step < ActiveRecord::Base
    SI_MANDATORY_FIELDS = []
    SI_FIELDS_MAPPING   = {}
    
    include Concerns::HasPersistantSynchronizationWithSiModel

    self.table_name = 'web_steps'

    AVERAGE_DEFAULT_SPEED = 90

    acts_as_mappable :default_unit => :kms,
                     :default_formula => :sphere,
                     :distance_field_name => :distance,
                     :lat_column_name => :lat,
                     :long_column_name => :long

    # has_and_belongs_to_many :web_commutes_steps
    # has_and_belongs_to_many :commutes, association_foreign_key: 'web_commute_id', foreign_key: 'web_step_id'

    scope :cities, -> { where(step_type: 'city') }
    scope :stations, -> { where(step_type: 'station') }
    
    # def self.default_scope
    #   where(is_city: false)
    # end

    def latlng
      [self.lat, self.lng]
    end

    def time_from_web_step(web_step, speed_average = AVERAGE_DEFAULT_SPEED)
    	(distance_from_web_step(web_step) / speed_average).hours
    end

    def distance_from_web_step(web_step)
      WebEngine::GeocoderProcessHelper.distance_between_web_cities(web_step, self)
    end

    def geocode
    	normal_geocode || reverse_geocode
    end

    def is_city
    	step_type == 'city'
    end

    def is_station
    	step_type == 'station'
    end

    def si_attributes
      { the_attributes_are: 'LES ATTRIBUTES DU SI POUR WEB::STEP' }
    end

    private

    def normal_geocode
      return unless has_city_name_but_not_coordinates

      city_params = WebEngine::GeocoderProcessHelper.geocode(self.name)

      self.lat    = city_params[:lat]
      self.lng    = city_params[:lng]
    end

    def reverse_geocode
      return unless has_coordinates_but_not_city_name

      city_params  = WebEngine::GeocoderProcessHelper.reverse_geocode(self.lat, self.lng)

      temporary_name = city_params[:city]

      # FIXME : Gérer le pb des différence "Nom-De-cette-manière" et "Nom de cette maniere"

      self.name   = city_params[:city]
    end

    def has_coordinates_but_not_city_name
      self.lat && self.lng && !self.name
    end

    def has_city_name_but_not_coordinates
      self.name && (!self.lat || !self.lng) 
    end
  end
end
