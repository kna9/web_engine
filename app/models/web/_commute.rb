module Web
  class Commute < ActiveRecord::Base
    SI_MANDATORY_FIELDS = []
    SI_FIELDS_MAPPING   = {}

    # include Concerns::HasPersistantSynchronizationWithSiModel
    include Concerns::HasNonPersistantSynchronizationWithSiModel

    self.table_name = 'web_commutes'

    AVERAGE_DEFAULT_SPEED = 90


    # JAVASCRIPT  : BUG MISE A JOUR DE TRAJET  (test NEUILLY ou Ivry)
    # SYNCHRO SI  : EN LECTURE ET EN ECRITURE
    # DESACTIVER LES LOGS GEOCODER

    #     EXPORT
    #       VITESSE (MOYENNE) (par defaut 90 KM)
    #       VILLE(s) PARCOURUE(s) (par defaut toutes)
    #       TRANCHE HORAIRE  (par defaut toutes)
    #       FILTRE : SEUIL...(nb trajet > x)

    #     EXPORT   
    #       "STATIONS COMPATIBLES"
    #            PAR STATION, LE NOMBRE DE TRAJETS COMPATIBLES

    belongs_to :from_city, :class_name => 'Web::City'
    belongs_to :to_city,   :class_name => 'Web::City'
    belongs_to :web_user,  :class_name => 'Web::User'


    # FIXME : DELETE @from and @to fields, we hase now @from_city and @to_city

    has_and_belongs_to_many :days,  -> { order('web_commutes_days.id')  }, association_foreign_key: 'web_day_id',  foreign_key: 'web_commute_id' 
    has_and_belongs_to_many :steps, -> { order('web_commutes_steps.id') }, association_foreign_key: 'web_step_id', foreign_key: 'web_commute_id'

    # has_and_belongs_to_many :choosen_web_stations, -> { order('commutes_choosen_stations.id') }, :join_table => 'commutes_choosen_stations', :class_name => 'Web::Station'
    def choosen_web_stations
      []
    end
    # has_and_belongs_to_many :compatible_web_stations, -> { order('web_commutes_compatible_stations.id') }, :join_table => 'web_commutes_compatible_stations', :class_name => 'WebStation'

    def self.create_all_commute_steps_report
      
      # Web::CommutesReport::WebCommutesRepor
      data_report = {}


      secure_key = CommutesReport.initialize_report('Tous les trajets déclarés')

      self.all.each do |web_commute|
        web_commute.steps_with_times.each do |step|
          if step.any? && step.count == 2 && step.first.first && step.last.first
            t1 = step.first.last
            t2 = step.last.last

            report_key = "#{step.first.first.id}_#{step.last.first.id}_#{t1}_#{t2}"

            if data_report[report_key] 
              data_report[report_key][0] = data_report[report_key][0].to_i + 1
            else
              data_report[report_key] = [1, [step.first.first, step.first.last], [step.last.first, step.last.last]]
            end
          end
        end
      end

      data_report.each do |key, value|
        if value && value.any? && value[0] && value[1] && value[1].any? && value[1][0] && value[1][1]&& value[2] && value[2].any? && value[2][0] && value[2][1]
          wc = CommutesReport.create(
            report_key: secure_key, 
            quantity:   value[0],
            from_id:    value[1][0].id, 
            from_name:  value[1][0].name, 
            from_lat:   value[1][0].lat, 
            from_lng:   value[1][0].lng, 
            from_time:  value[1][1], 
            to_id:      value[2][0].id, 
            to_name:    value[2][0].name, 
            to_lat:     value[2][0].lat, 
            to_lng:     value[2][0].lng,
            to_time:    value[2][1]
          )
        end
      end

      secure_key
    end

    def from
      from_city
    end

    def to
      to_city
    end

    def update_from_web_form(parameters = nil)
      initialize_or_update_from_web_form(true, parameters)
    end

    def create_from_web_form(parameters = nil)
      initialize_or_update_from_web_form(false, parameters)
    end

    def suggested_web_stations(km_zone = 3)
      choosen = []

      # FIXME : A REMETTRE

      # self.choosen_web_stations(km_zone).each do |st|
      #   choosen << st
      # end

      result  = compatible_web_stations - choosen

      result
    end

    def compatible_web_stations(km_zone = 3)
      compatible_web_stations = []

      Station.all.each do |web_station|
        commute_steps.each do |step|
          if step.distance_from_web_step(web_station).to_f <= km_zone.to_f
            compatible_web_stations << web_station unless compatible_web_stations.include?(web_station)
          end
        end
      end

      compatible_web_stations
    end

    def steps_with_times(speed_average = AVERAGE_DEFAULT_SPEED)
      steps_with_times = []

      old_time = self.time ? self.time : '00:00'.to_time
      old_city = self.from_city
      detours  = self.steps

      begin
        part_cities  = []

        part_cities << [ old_city, short_time(old_time) ]

        detours.each do |detour_city|
          new_time = short_time(old_time).to_time + detour_city.time_from_web_step(old_city, speed_average)

          part_cities << [ detour_city, short_time(new_time)]

          steps_with_times << part_cities

          old_time = new_time
          old_city = detour_city

          part_cities = []
          part_cities << [ detour_city, short_time(old_time)]
        end

        new_time = short_time(old_time).to_time + self.to_city.time_from_web_step(old_city, speed_average)
        part_cities << [ self.to_city, short_time(new_time) ]

        steps_with_times << part_cities
      rescue
        steps_with_times = if self.from_city && self.to_city
          [
            [self.from_city, short_time(old_time)], 
            [self.to_city, short_time(short_time(old_time).to_time + self.to_city.time_from_web_step(self.from_city, speed_average))] 
          ]
        else 
          []
        end
      end


      steps_with_times
    end

    def short_time(real_time)
      (real_time && real_time.to_time) ? real_time.strftime("%H:%M") : "00:00"
    end

    def commute_steps
      commute_steps = []

      commute_steps << from

      steps.each do |step|
        commute_steps << step
      end

      commute_steps << to
      commute_steps
    end

    def line_message
      'FIXME : A CHANGER MESSAGE QUAND TRAJET PASSE PAR LIGNE'
    end

    def on_the_line?
      true
    end

    def via   
      steps.map(&:name)
    end

    def stations
      choosen_web_stations.map(&:id).map(&:to_s)
    end

    def dow
      web_days.map { |wd| wd.id-1 }
    end

    def si_attributes
      { the_attributes_are: 'LES ATTRIBUTES DU SI POUR WEB::COMMUTE' }
    end

    private

    def convert_ui_parameters_to_model_parameters(parameters)
      # FIXME: vérifier l'utilité de authentification_token

      processed_parameters = {
        name: '',
        time: '',
        time_delta: '',
        detour_delta: '',
        authentication_token: ''
      }

      if parameters
        processed_parameters[:name] = "Trajet #{parameters['from']} #{parameters['to']}" if parameters['from'] && parameters['to']
        processed_parameters[:time] =  parameters['time'] if parameters['time']
        processed_parameters[:time_delta] = parameters['time_delta'] if parameters['time_delta']
        processed_parameters[:detour_delta] = parameters['detour_delta'] if parameters['detour_delta']
        processed_parameters[:authentication_token] = parameters['authentication_token'] if parameters['authentication_token']
      end

      processed_parameters
    end

    def initialize_or_update_from_web_form(update = false, parameters = nil)
      # FIXME : cette methode est bien trop longue : refactoriser
      via_parameter       = parameters['via'] if parameters
      stations_parameter  = parameters['stations'] if parameters
      dow_parameter       = parameters['dow'] if parameters
      from_name_parameter = parameters['from'] if parameters
      to_name_parameter   = parameters['to'] if parameters
      parameters          = convert_ui_parameters_to_model_parameters(parameters)

      update ? self.update_attributes(parameters) : self.assign_attributes(parameters)

      # web_days
      if dow_parameter 
        self.web_days = [] if update

        eval(dow_parameter).each do |id|
          web_days << WebDay.find(id + 1)
        end
      end

      # steos
      if via_parameter
        self.web_steps = [] if update

        via_parameter.compact.reject(&:empty?).each do |name|
          step = WebCity.find_by_name(name) # FIXME : kezako des "-" etc...
          step = WebCity.create({ name: name, city: name, short_name: name, step_type: 'city' }) unless step

          steps << step
        end
      end

      if stations_parameter
        self.choosen_web_stations = [] if update
        stations_parameter.reject(&:empty?).compact.map(&:to_i).each do |id|
          choosen_web_stations << WebStation.find(id) 
          # FIXME : a vérifier si on doit les find par l'id ou le si_id
        end
      end

      city_from = WebCity.find_by_name(from_name_parameter)
      city_to   = WebCity.find_by_name(to_name_parameter)

      self.from_city = city_from if city_from
      self.to_city   = city_to if city_to

      self.save!
    end
  end
end