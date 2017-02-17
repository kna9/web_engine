module Concerns
  module HasGeocodingProperties

    # -------------------------------------------------------------------------------------------------------------------------------------
    # FIXME : /home/vagrant/.rbenv/versions/2.3.0/lib/ruby/gems/2.3.0/gems/geokit-rails-2.2.0/lib/geokit-rails/acts_as_mappable.rb:44
    #
    # bug config geokit rails fixé comme ceci : 
    #    self.lat_column_name = 'lat'  # options[:lat_column_name] || 'lat'
    #    self.lng_column_name = 'long' # options[:lng_column_name] || 'lng'
    #
    # patch soit a jouer sur gem local, soit jouer un 'monkey patch' pour modifier la classe
    # -------------------------------------------------------------------------------------------------------------------------------------

    extend ActiveSupport::Concern

    included do
      acts_as_mappable :default_unit => :kms,
                       :default_formula => :sphere,
                       :distance_field_name => :distance,
                       :lat_column_name => :lat,
                       :long_column_name => :long

      alias_attribute :lng, :long

      # geocoded_by :address, :latitude  => :lat, :longitude => :lon
      # reverse_geocoded_by :latitude, :longitude, :address => :location

      def latlng
        [self.lat, self.lng]
      end

      def time_from(geocodable_object, speed_average = 90)
        (distance_from(geocodable_object) / speed_average).hours
      end

      def distance_from(geocodable_object)
        WebEngine::GeocoderProcessHelper.distance_between_web_cities(geocodable_object, self)
      end

      def geocode
        normal_geocode || reverse_geocode
      end

      private

      def normal_geocode
        return unless has_city_name_but_not_coordinates

        city_params = WebEngine::GeocoderProcessHelper.geocode(self.name)

        self.lat    = city_params[:lat]
        self.long    = city_params[:lng]
      end

      def reverse_geocode
        return unless has_coordinates_but_not_city_name

        city_params  = WebEngine::GeocoderProcessHelper.reverse_geocode(self.lat, self.lng)

        temporary_name = city_params[:city]

        self.name   = city_params[:city]     # FIXME : Gérer le pb des différence "Nom-De-cette-manière" et "Nom de cette maniere"
      end

      def has_coordinates_but_not_city_name
        self.lat && self.lng && !self.name
      end

      def has_city_name_but_not_coordinates
        self.name && (!self.lat || !self.lng) 
      end
    end
  end
end
