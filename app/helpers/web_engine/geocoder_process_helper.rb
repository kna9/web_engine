module WebEngine
  class GeocoderProcessHelper
    class << self
      include Geokit::Geocoders

      def geocode(city_name)
        geocode_result = MultiGeocoder.geocode("#{city_name}, FR")

        extract_first_item_from_geocode_result(MultiGeocoder.geocode("#{city_name}, FR"))
      end

      def reverse_geocode(lat, lng)
        extract_near_city_item_from_geocode_result(Geokit::Geocoders::MultiGeocoder.reverse_geocode "#{lat},#{lng}")
      end

      def distance_between_web_cities(web_city1, web_city2)
        ::Geocoder::Calculations.distance_between(web_city1.latlng, web_city2.latlng) * 1.609344
      end

      private

      def extract_first_item_from_geocode_result(geocode_result)
        result = geocode_result.all[0] if geocode_result && geocode_result.all && geocode_result.all.any?

        object_format_form_geocode_result_item(result) if result
      end

      def extract_near_city_item_from_geocode_result(geocode_result)
        return unless geocode_result
        return unless geocode_result.all
        return unless geocode_result.all.any?

        near_city_name = nil

        geocode_result.all.each do |result_item|
          if result_item.city && !result_item.city.empty?
            near_city_name = result_item.city
            next
          end
        end

        return geocode(near_city_name) 
      end

      def object_format_form_geocode_result_item(item_result)
        {
          city: item_result.city == nil ? "#{item_result.lat}/#{item_result.lng} (#{item_result.province}, #{item_result.district})" : item_result.city,      
          lat:  item_result.lat,      
          lng:  item_result.lng
        }
      end
    end
  end
end