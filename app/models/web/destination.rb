module Web
  class Destination < SI::Destination
    include Concerns::HasGeocodingProperties

    def test
      SaveModelService.new.perform
    end
  end
end
