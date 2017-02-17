module Web
  class Location < SI::Location
    include Concerns::HasGeocodingProperties
  end
end
