module Web
  class Location < ActiveRecord::Base
    include Concerns::HasGeocodingProperties
    include Concerns::HasSiSynchronization
  end
end
