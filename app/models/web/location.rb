module Web
  class Location < ActiveRecord::Base
    include Concerns::HasGeocodingProperties
    include Concerns::HasSiSynchronization

    def compatible_commutes
      doublons_filtered(Web::Commute.where(id: CommutesLocation.where(location_id: id).map(&:commute_id)))
    end

    private

    def doublons_filtered(commutes_list)
      doublon_filtered_commutes = {}

      commutes_list.each do |commute|
        doublon_filtered_commutes[key_for_commute(commute)] = commute
      end
      
      doublon_filtered_commutes.values
    end

    def key_for_commute(commute)
      dow_key  = commute.dow.to_a.compact.sort.uniq.map(&:to_s).join('-')
      from_key = commute.from_city.name.to_s.upcase
      to_key   = commute.to_city.name.to_s.upcase
      time_key = commute.formated_departure_time.to_s.upcase
      user_key = commute.user.id.to_s

      "#{user_key}_#{from_key}_#{to_key}_#{time_key}_#{dow_key}"
    end
  end
end
