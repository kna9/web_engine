module Web
  class Location < ActiveRecord::Base
    include Concerns::HasGeocodingProperties
    include Concerns::HasSiSynchronization

    def formatted_address
      station_address = nil
      station_geocode = JSON.load(open("http://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{long}&sensor=true_or_false"))

      if station_geocode && station_geocode['results'] && station_geocode['results'].any? && station_geocode['results'].first && station_geocode['results'].first['formatted_address']
        station_address = station_geocode['results'].first['formatted_address']
      end

      return station_address
    end
  end
end
