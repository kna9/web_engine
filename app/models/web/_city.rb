module Web
  class City < Web::Step
    STEP_TYPE = 'city'

    has_many :web_commutes

    has_many :from_web_commutes,   :class_name => "Web::Commute", :foreign_key => "from_city_id"
    has_many :to_web_commutes,     :class_name => "Web::Commute", :foreign_key => "to_city_id"


    before_save :geocode_coordinates_and_set_city_to_true
    before_create :geocode_coordinates_and_set_city_to_true

    def self.default_scope
      where(step_type: STEP_TYPE)
    end

    def latlng
      [ lat, lng ]
    end

    private

    def geocode_coordinates_and_set_city_to_true
      self.geocode

      self.city         = self.name
      self.short_name   = self.name
      self.default_dest = self.name
      self.active       = true

      set_city_to_true
    end

    def set_city_to_true
      self.step_type = STEP_TYPE
    end
  end
end
