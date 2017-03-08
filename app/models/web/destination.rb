module Web
  class Destination < ActiveRecord::Base
    include Concerns::HasGeocodingProperties
    include Concerns::HasSiSynchronization
  end
end
