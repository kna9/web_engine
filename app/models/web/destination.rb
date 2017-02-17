module Web
  class Destination < SI::Destination
    include Concerns::HasGeocodingProperties
  end
end
