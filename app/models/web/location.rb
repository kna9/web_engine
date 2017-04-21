module Web
  class Location < ActiveRecord::Base
    include Concerns::HasGeocodingProperties
    include Concerns::HasSiSynchronization

    def compatible_commutes
      Web::Commute.where(id: CommutesLocation.where(location_id: id).map(&:commute_id))
    end
  end
end
