module Web
  # Web::Destination.by_distance(:origin => [49.147956, 1.994782]).first

  class Commute < ActiveRecord::Base
    SPEED_AVERAGE      = 50
    KM_DETOUR          = 5
    MILES_PER_KM       = 1.6
    DETOUR_DELTA_LIMIT = 20 # 10

    include Concerns::HasSiSynchronization

    def save_all_commute_locations
      Web::Location.all.each do |location|
        save_commute_location_link(location)
      end
    end

    def save_commute_location_link(location)
      existing_record = CommutesLocation.where(commute_id: id, location_id: location.id).first

      if is_compatible_commute(location)
        unless existing_record
          commutes_location = CommutesLocation.new(commute_id: id, location_id: location.id)
          commutes_location.save
        end
      else
        if existing_record
          existing_record.delete
        end
      end
    end

    def save_detours(commute_id)
      if commute_id
        connection = ActiveRecord::Base.connection.raw_connection
        sql = "delete from db_commute_destinations where commute_user_id=$1 and commute_id=$2"
        
        begin
          connection.prepare('del_commute_destination', sql)
        rescue PG::DuplicatePstatement => e
        end
        
        st = connection.exec_prepared('del_commute_destination', [ user_id, commute_id ])

        detours.each do |detour_destination|
          location_to_save = DbCommuteDestination.new(commute_user_id: user_id, commute_id: commute_id, detour_id: detour_destination.id)
          begin
            location_to_save.save
          rescue
            true
          end
        end
      end
    end

    def save_stations(commute_id)
      if commute_id

        connection = ActiveRecord::Base.connection.raw_connection
        sql = "delete from db_commute_locations where commute_user_id=$1 and commute_id=$2"
        
        begin
          connection.prepare('del_commute_location', sql)
        rescue PG::DuplicatePstatement => e
        end

        st = connection.exec_prepared('del_commute_location', [ user_id, commute_id ])

        stations.each do |station_location|
          station_to_save = DbCommuteLocation.new(commute_user_id: user_id, commute_id: commute_id, station_id: station_location.id)
          begin
            station_to_save.save
          rescue
            true
          end
        end
      end
    end

    def compatible_locations
      Web::Location.where(id: CommutesLocation.where(commute_id: id).map(&:location_id))
    end

    def user
      @user ||= Web::User.where(id: user_id).first
    end

    def detours 
      @detours ||= get_detours
    end

    def db_detours_ids
      @db_detours_ids ||= Web::DbCommuteDestination.where(commute_id: id).map(&:detour_id) # self.detours.to_a.map(&:id)
    end

    def stations
      @stations ||= get_stations
    end

    def db_stations_ids
      @db_stations_ids ||= Web::DbCommuteLocation.where(commute_id: id).map(&:station_id) #self.stations.to_a.map(&:id)
    end

    def start
      @start ||= Web::Destination.where(id: start_id).first
    end

    def end
      @end ||= Web::Destination.where(id: end_id).first
    end

    def name
      @name ||= "#{self.start.name} > #{self.end.name}"
    end

    alias_method :from, :start
    alias_method :from_city, :start
    alias_method :to, :end
    alias_method :to_city, :end

    ################## REPORTS & EQUIVALENT CONDUCTEURS

    def time_engagement
      ((time2 - time1) / 60).to_i # FIXME : le /60 : c'est parcequ'on est en secondes...???
    end

    def passage_time_engagement(location)
      ((passage_time2(location) - passage_time1(location)) / 60).to_i
    end

    def ec # FIXME : change ec >> driver_equivalant
      ec = {}

      quarters_times_intervals.each do |t|
        ec[t] = process_driver_equivalant(t.first.to_time, t.last.to_time)
      end

      ec
    end

    def ec_sum
      ec_sum = 0.0

      ec.each do |key, ec_value|
        ec_sum = ec_sum + ec_value
      end

      ec_sum
    end

    def converted_time
      time.utc.strftime("%H:%M")
    end

    def process_driver_equivalant(time_min, time_max)
      (time_min..time_max).include?(converted_time.to_time) ? driver_equivalant_value : 0
    end

    def driver_equivalant_value
      probability, weighting = if time_engagement > 0 && time_engagement <= 15
        [ 1, 1 ]
      elsif time_engagement > 15 && time_engagement <= 30
        [ 0.7, 0.5 ]
      elsif time_engagement > 30 && time_engagement <= 60
        [ 0.5, 0.25 ]
      else
        [ 0, 0 ]
      end

      probability * weighting
    end

    ################## TIME CONVERSION

    def display_passage_time(location)
      passage_time_to_station(location) ? formated_time(passage_time_to_station(location)) : ''
    end

    def display_passage_time_min(location)
      if passage_time_to_station(location)
        passage_time_min = passage_time1(location)
        formated_time(passage_time_min)
      end   
    end

    def display_passage_time_max(location)
      if passage_time_to_station(location)
        passage_time_max = passage_time2(location)
        formated_time(passage_time_max)
      end 
    end

    def passage_time1(location) 
      passage_time_to_station(location) - time_delta.minutes
    end

    def passage_time2(location)
      passage_time_to_station(location) + time_delta.minutes
    end

    def formated_departure_time
      formated_time(time)
    end

    def formated_time(param_time)
      param_time.to_s.split(' ')[1].split(':')[0..1].join('H').gsub('H00','H')
    end

    def process_converted_time
      convert_time(time)
    end

    def convert_time(t)
      t.utc.strftime("%H%M%S%N")
    end

    def converted_time
      time.utc.strftime("%H:%M")
    end

    def time1
      time - time_delta.minutes
    end

    def time2
      time + time_delta.minutes
    end

    ################## COMMUTES SEARCH ENGINE

    def self.extract_utc_time(utc_time)
      utc_time.to_s.split(' ')[1].to_time.utc
    end

    def self.search_commutes(args = {})
      whish_location       = args[:location]
      whish_destination    = args[:destination]
      whish_days_of_week    = args[:dow]

      whish_departure_time     = args[:time].to_time if args[:time]
      param_whish_departure_time_max = args[:time_max].to_time if args[:time_max]

      return [] unless whish_location
      return [] unless whish_destination
      return [] unless whish_days_of_week
      return [] unless whish_departure_time

      whish_departure_time     = extract_utc_time(whish_departure_time.utc)
      whish_departure_time_min = whish_departure_time - 30.minutes
      whish_departure_time_max = whish_departure_time + 30.minutes

      if param_whish_departure_time_max
        whish_departure_time_min = whish_departure_time
        whish_departure_time_max = extract_utc_time(param_whish_departure_time_max.utc)
      end

      results = []

      whish_itinerary = []

      begin
        whish_itinerary = GeoProcessService.new.osrm_itinerary(whish_location, whish_destination)
      rescue
        # FIXME : Sentry send OSRM KO
        whish_itinerary = GeoProcessService.new.theorical_itinerary(whish_location, whish_destination)
      end

      # raise Web::Commute.declared_for_dows(whish_days_of_week).map(&:id).include?(146).inspect

      Web::Commute.declared_for_dows(whish_days_of_week).each do |commute|
        results << commute if commute.compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time_min, whish_departure_time_max)
      end

      return results
    end

    ##################

    def self.declared_for_dows(days_ids)
      compatible_dow_commutes = []

      Web::Commute.all.each do |commute|
        compatible_dow_commutes << commute if commute.is_declared_for_dows?(days_ids)
      end

      return compatible_dow_commutes
    end

    def passage_time_to_station(location)
      index_of_passage = index_of_passage(location)

      return false unless index_of_passage

      return itinerary.waypoints_with_times(time)[index_of_passage].last
    end

    def is_compatible_commute(location)
      index_of_departure = index_of_passage(location)

      # FIXME : va retourner beaucoup de result...

      return index_of_departure ? true : false
    end

    def compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time_min, whish_departure_time_max)
      index_of_departure = index_of_passage(whish_itinerary.waypoints.first)
      #raise index_of_departure.inspect
      index_of_arrival   = index_of_passage(whish_itinerary.waypoints.last)

      return false unless index_of_departure
      return false unless index_of_arrival
      return false if index_of_departure >= index_of_arrival

      return compatible_departure = compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time_min, whish_departure_time_max) 
    end

    def compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time_min, whish_departure_time_max)
      waypoint_passage_time = itinerary.waypoints_with_times(time)[index_of_departure].last
      # FIXME: classé par éloignement de l'heure désirée

      min_time = Web::Commute.extract_utc_time(waypoint_passage_time) - time_delta.minutes
      max_time = Web::Commute.extract_utc_time(waypoint_passage_time) + time_delta.minutes
      
      compatible_departure = (min_time >= whish_departure_time_min && min_time <= whish_departure_time_max) || (max_time >= whish_departure_time_min && max_time <= whish_departure_time_max)
      # FIXME : tester et vérif : !(max_time < whish_departure_time_min || min_time > whish_departure_time_max) (manque des bornes)

      return compatible_departure
    end

    def index_of_passage(passage_waypoint)
      distances_and_indexes = []

      dtcc = []

      # if id == 146
      #   raise passage_waypoint.inspect
      # end

      itinerary.waypoints.each_with_index do |waypoint, index|
        # FIXME : modifier la conf pour avoir les distances en KM
        processed_distance = waypoint.distance_from(passage_waypoint).to_f * 1.6 # * MILES_PER_KM

        #raise processed_distance.inspect
        #raise id.inspect

        
        # if id == 146
        #   dtcc << processed_distance
        # end

        if processed_distance <= detour_kilometers
          #raise 'ok'
          distances_and_indexes << [processed_distance, index]
        end
      end

      # raise dtcc.inspect if id == 146

      return distances_and_indexes.any? ? distances_and_indexes.sort.first.last : nil
    end

    def theorical_itinerary
      @theorical_itinerary ||= GeoProcessService.new.theorical_itinerary(from, to)
    end

    def osrm_itinerary
      # BE CARFULE : API call
      @osrm_itinerary ||= GeoProcessService.new.osrm_itinerary(from, to)
    end

    def itinerary
      # FIXME: performence issu when to much waypoints
      return @itinerary if @itinerary
      wp = []
      wp << from
      wp = wp + get_itinerary_from_waypoints
      wp << to
      @itinerary = Web::Itinerary.new( { waypoints: wp })
      return @itinerary
    end

    def is_declared_for_dows?(days_ids)
      days_ids && dow && !(days_ids & dow).empty?
    end

    def detour_kilometers
      limited_detour_delta = detour_delta
      limited_detour_delta = DETOUR_DELTA_LIMIT if limited_detour_delta > DETOUR_DELTA_LIMIT

      detour_commuted = (limited_detour_delta.to_f * (Web::Itinerary::SPEED_AVERAGE.to_f/60.to_f).to_f) / 2 

      detour_min      = Web::Itinerary::KM_DETOUR_MIN.to_f

      detour_kilometers = if detour_commuted <= detour_min
        detour_min
      else
        detour_commuted
      end

      return detour_kilometers
    end

    private

    ################## UTILS

    def get_detours
      detours = []
      db_detours_ids.each do |detour_id|
        detours << Web::Destination.where(id: detour_id).first
      end

      detours
    end

    def get_stations
      stations = []
      db_stations_ids.each do |station_id|
        stations << Web::Location.where(id: station_id).first
      end

      stations
    end

    def get_itinerary_from_waypoints
      itinerary_from_waypoints = []

      get_filtered_waypoints.each do |waypoint|
        itinerary_from_waypoints << Web::Destination.new(lat: waypoint.first, long: waypoint.last)
      end

      return itinerary_from_waypoints
    end

    def get_filtered_waypoints
      return @filtered_waypoints if @filtered_waypoints
      return [] unless waypoints
      return [] if waypoints == ''

       @filtered_waypoints = nil

      begin
        @filtered_waypoints = JSON.parse(waypoints)
      rescue
        @filtered_waypoints = nil
      end

      return [] unless @filtered_waypoint

      slice_val = @filtered_waypoints.count > 30 ? ((@filtered_waypoint.count/100)+1)*10 : 3
      @filtered_waypoints = @filtered_waypoints.each_slice(slice_val).map(&:last)

      return @filtered_waypoints
    end

    def quarters_times_intervals
      (0..23).each.flat_map { |hour| [["#{hour}:00", "#{hour}:15"], ["#{hour}:15", "#{hour}:30"], ["#{hour}:30", "#{hour}:45"], ["#{hour}:45", "#{ hour+1 < 24 ? hour+1 : 0}:00"]] }
    end
  end
end