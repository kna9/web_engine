module Web
  class Station < Web::Step
    STEP_TYPE = 'station'
    # has_and_belongs_to_many :web_commutes
    has_many :web_commutes

    before_save :set_station_to_true
    before_create :set_station_to_true

    def self.default_scope
      where(step_type: STEP_TYPE)
    end

    def set_station_to_true
      self.step_type = STEP_TYPE
    end
  end
end
