module Web
  class DbCommute
    SI_MANDATORY_FIELDS = [ :id ]


    # ----------------------------------------------

    # cs = Web::DbCommute.get_all_commutes
    # cs = Web::DbCommute.get_all_commutes_for_user(user_id)
    # cs = Web::DbCommute.get_all_commutes_for_station(user_id, station_id)

    # c = Web::DbCommute.new(id: 404)
    # c.get_from_si

    # t = Web::Trip.new({ location: Location.first, destination: Destination.first, date_and_time: '03/02/2017 08:45:00'})
    # t.get_from_si

    # ----------------------------------------------

    # FIXME : get the commute for a user...

    # FIXME : remplacer a tous les niveaux les notins de DbCommute >>> en Commute pour remplacer les Commutes.

    # verify if si id: :id enabled

    SI_FIELDS_MAPPING   = {
      created_at:   :created_at,
      updated_at:   :updated_at,
      dow:          :dow,
      time:         :time,
      detour_delta: :detour_delta,
      user_id:      :user_id,
      start_id:     :start_id,
      end_id:       :end_id,
      detours:      :detours,
      stations:     :stations
    }

    include Concerns::HasNonPersistantSynchronizationWithSiModel

    attr_accessor :id, :created_at, :updated_at, :dow, :time, :detour_delta, :user_id, :start_id, :end_id, :detours, :stations,:time_delta

    # '28/12/2016 21:28:29'

    def self.get_model(model_name, filters = {})
      # FIXME : exemple pour remplacer les models active record: 
      # http://stackoverflow.com/questions/19772111/is-it-possible-to-use-activeadmin-on-a-non-activerecord-based-model-say-activem
      # générer dynamiquement des models qui héritent de Web::Model en fonction de leur classname, recupérer les attr_attributes du si
      
      WebEngine::SiClient.initialize_connection
      rpc_client = WebEngine::RpcClient.new

      all_models_response = rpc_client.send('get_model', { model_name: model_name, filters: filters })

      return [] unless all_models_response.status_code == 200

      all_models = []
      hash_models = all_models_response.response_object['models']

      return hash_models
    end      

    def self.get_commutes(args = {})
      # Web::DbCommute.get_commutes({ location: Location.last, destination: Destination.first, time: '08:30'.to_time, dow: [1,2,3]})
      si_location = args[:location]

      return get_all_commutes unless si_location


      si_destination    = args[:destination]
      day_of_week       = args[:dow]
      departure_time    = args[:time]

      si_location_id    = si_location.id if si_location
      si_destination_id = si_destination.id if si_destination

      km_detour_approximation = 1 # FIXME: depends on detour declared (en temps donc simuler vitesse)

      choosen_web_station           = Web::Station.where(si_id: si_location_id).first
      near_choosen_location_stations = Web::Station.within(km_detour_approximation, origin: choosen_web_station)
      near_choosen_location_steps    = Web::Step.within(km_detour_approximation, origin: choosen_web_station)

      near_choosen_location_stations_ids = near_choosen_location_stations.map(&:si_id)
      near_choosen_location_steps_ids    = near_choosen_location_steps.map(&:si_id)

      if si_destination_id
        choosen_web_destination           = Web::Step.where(si_id: si_destination_id).first
        near_choosen_destination_stations = Web::Station.within(km_detour_approximation, origin: choosen_web_destination)
        near_choosen_destination_steps    = Web::Step.within(km_detour_approximation, origin: choosen_web_destination)

        near_choosen_destination_stations_ids = near_choosen_destination_stations.map(&:si_id)
        near_choosen_destination_steps_ids    = near_choosen_destination_steps.map(&:si_id)
      end

      near_stations_ids = (near_choosen_location_stations_ids + near_choosen_destination_stations_ids.to_a).uniq
      near_steps_ids = (near_choosen_location_steps_ids + near_choosen_destination_steps_ids.to_a).uniq

      WebEngine::SiClient.initialize_connection
      rpc_client = WebEngine::RpcClient.new

      all_commutes_response = rpc_client.send('get_all_commutes', {})

      return [] unless all_commutes_response.status_code == 200

      acm = []
      hash_commutes = all_commutes_response.response_object['commutes']

      hash_commutes.each do |hash_commute|
        commute_ok = false

        start_id = hash_commute['start_id']
        end_id   = hash_commute['end_id']
        detours  = hash_commute['detours']
        stations = hash_commute['stations']

        if near_steps_ids.include?(start_id) || near_steps_ids.include?(end_id) || (detours & near_steps_ids).any?
          commute_ok = true 
        end

        if (stations & near_stations_ids).any?
          commute_ok = true 
        end

        # --exclusions conditions with day_of_week || departure_time

        if day_of_week && day_of_week.any?
          si_dow  = hash_commute['dow']  # [0,1,2,3]

          unless (day_of_week & si_dow).any?
            commute_ok = false
          end 
        end

        if departure_time
          si_time = hash_commute['time'] # "08:30".to_time
          if si_time
            si_time = si_time.to_time
          end

          time_delta = hash_commute['time_delta']
          time_delta = 0 unless time_delta
          time_delta = time_delta.to_i

          min_time = si_time - time_delta.seconds
          max_time = si_time + time_delta.seconds
          
          if departure_time < min_time || departure_time > max_time
            commute_ok = false
          end
        end

        if commute_ok == true
          acm << Web::DbCommute.new(hash_commute) 
        end
      end

      return acm
    end

    def self.get_all_commutes
      WebEngine::SiClient.initialize_connection
      rpc_client = WebEngine::RpcClient.new

      all_commutes_response = rpc_client.send('get_all_commutes', {})

      return [] unless all_commutes_response.status_code == 200

      all_commutes = []
      hash_commutes = all_commutes_response.response_object['commutes']

      hash_commutes.each do |hash_commute|
        all_commutes << Web::DbCommute.new(hash_commute)
      end

      return all_commutes
    end

    def initialize(args = {})
      args.each do |key, value|
      	self.send("#{key}=", value)
      end

      # FIXME : impossible d'initialize automatiquement car le SI renvoie une Hash et non un objet...
      # self.get_from_si
    end

    # public methods to map commutes

    def from_city
      @from_city ||= get_from_city
    end

    def to_city
      @to_city ||= get_to_city
    end

    def steps
      @steps ||= get_steps
    end

    def choosen_web_stations
      @choosen_web_stations ||= get_choosen_web_stations
    end

    def days 
      @days ||= get_days
    end

    def user
      @user ||= get_user
    end

    private

    def get_from_city
      Web::Step.where(si_id: start_id).first
    end

    def get_to_city
      Web::Step.where(si_id: end_id).first
    end

    def get_steps
      return [] unless detours

      web_steps = []

      detours.each do |detour_id|
        web_steps << Web::Step.where(si_id: detour_id).first
      end

      web_steps.compact
    end

    def get_choosen_web_stations
      return [] unless stations

      web_stations = []

      stations.each do |station_id|
        web_stations << Web::Station.where(si_id: station_id).first
      end

      web_stations.compact
    end

    def get_days
      web_dow = []

      dow.each do |day_id|
        web_dow << Web::Day.where(id: day_id).first
      end

      web_dow.compact
    end

    def get_user
      User.where(id: self.user_id).first
    end
  end
end
