module Web
  # Web::Destination.by_distance(:origin => [49.147956, 1.994782]).first

  class Commute < ActiveRecord::Base
    SPEED_AVERAGE = 50
    KM_DETOUR     = 5

    include Concerns::HasSiSynchronization

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

    QUARTERS =  [
      ['0:00', '0:15'], ['0:15', '0:30'], ['0:30', '0:45'], ['0:45', '1:00'], ['1:00', '1:15'], ['1:15', '1:30'], ['1:30', '1:45'], ['1:45', '2:00'],
      ['2:00', '2:15'], ['2:15', '2:30'], ['2:30', '2:45'], ['2:45', '3:00'], ['3:00', '3:15'], ['3:15', '3:30'], ['3:30', '3:45'], ['3:45', '4:00'],
      ['4:00', '4:15'], ['4:15', '4:30'], ['4:30', '4:45'], ['4:45', '5:00'], ['5:00', '5:15'], ['5:15', '5:30'], ['5:30', '5:45'], ['5:45', '6:00'],
      ['6:00', '6:15'], ['6:15', '6:30'], ['6:30', '6:45'], ['6:45', '7:00'], ['7:00', '7:15'], ['7:15', '7:30'], ['7:30', '7:45'], ['7:45', '8:00'],
      ['8:00', '8:15'], ['8:15', '8:30'], ['8:30', '8:45'], ['8:45', '9:00'], ['9:00', '9:15'], ['9:15', '9:30'], ['9:30', '9:45'], ['9:45', '10:00'],
      ['10:00', '11:15'], ['10:15', '10:30'], ['10:30', '10:45'], ['10:45', '11:00'], ['11:00', '11:15'], ['11:15', '11:30'], ['11:30', '11:45'], ['11:45', '12:00'],
      ['12:00', '12:15'], ['12:15', '12:30'], ['12:30', '12:45'], ['12:45', '13:00'], ['13:00', '13:15'], ['13:15', '13:30'], ['13:30', '13:45'], ['13:45', '14:00'],
      ['14:00', '14:15'], ['14:15', '14:30'], ['14:30', '14:45'], ['14:45', '15:00'], ['15:00', '15:15'], ['15:15', '15:30'], ['15:30', '15:45'], ['15:45', '16:00'],      
      ['16:00', '16:15'], ['16:15', '16:30'], ['16:30', '16:45'], ['16:45', '17:00'], ['17:00', '17:15'], ['17:15', '17:30'], ['17:30', '17:45'], ['17:45', '18:00'],
      ['18:00', '18:15'], ['18:15', '18:30'], ['18:30', '18:45'], ['18:45', '19:00'], ['19:00', '19:15'], ['19:15', '19:30'], ['19:30', '19:45'], ['19:45', '20:00'],
      ['20:00', '20:15'], ['20:15', '20:30'], ['20:30', '20:45'], ['20:45', '21:00'], ['21:00', '21:15'], ['21:15', '21:30'], ['21:30', '21:45'], ['21:45', '22:00'],
      ['22:00', '22:15'], ['22:15', '22:30'], ['22:30', '22:45'], ['22:45', '23:00'], ['23:00', '23:15'], ['23:15', '23:30'], ['23:30', '23:45'], ['23:45', '0:00']
    ]

    ################## REPORTS

    def time_engagement
      ((time2 - time1) / 60).to_i
    end

    def passage_time_engagement(location)
      ((passage_time2(location) - passage_time1(location)) / 60).to_i
    end

    def ec
      ec = {}

      QUARTERS.each do |t|
        ec[t] = process_ec(t)
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

    def process_ec(times)
      retour = 0


      if (times.first.to_time..times.last.to_time).include?(converted_time.to_time)
        retour = param_a + param_b
      end

      return retour
    end

    def param_a
      if time_engagement > 0 && time_engagement <= 15
        1
      elsif time_engagement > 15 && time_engagement <= 30
        0.7
      elsif time_engagement > 30 && time_engagement <= 60
        0.5
      else
        0
      end
    end

    def param_b
      if time_engagement > 0 && time_engagement <= 15
        1
      elsif time_engagement > 15 && time_engagement <= 30
        0.5
      elsif time_engagement > 30 && time_engagement <= 60
        0.25
      else
        0
      end 
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

    def self.search_commutes(args = {})
      whish_location       = args[:location]
      whish_destination    = args[:destination]
      whish_day_of_week    = args[:dow]
      whish_departure_time = args[:time].to_time if args[:time]

      return [] unless whish_location
      return [] unless whish_destination
      return [] unless whish_day_of_week
      return [] unless whish_departure_time

      results = []

      whish_itinerary = []

      begin
        whish_itinerary = GeoProcessService.new.osrm_itinerary(whish_location, whish_destination)
      rescue
        whish_itinerary = GeoProcessService.new.theorical_itinerary(whish_location, whish_destination)
      end

      Web::Commute.dow_compatible(whish_day_of_week).each do |commute|
        results << commute if commute.compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time)
      end

      return results
    end

    def self.dow_compatible(day_of_week)
      compatible_dow_commutes = []

      Web::Commute.all.each do |commute|
        compatible_dow_commutes << commute if commute.compatible_dow?(day_of_week)
      end

      return compatible_dow_commutes
    end

    def passage_time_to_station(location)
      index_of_passage = index_of_passage(location)

      return false unless index_of_passage

      return itinerary.waypoints_with_times(time)[index_of_passage].last
    end

    def compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time)
      index_of_departure = index_of_passage(whish_itinerary.waypoints.first)
      index_of_arrival   = index_of_passage(whish_itinerary.waypoints.last)

      return false unless index_of_departure
      return false unless index_of_arrival
      return false if index_of_departure >= index_of_arrival

      return compatible_departure = compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time) 
    end

    def compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time)
      waypoint_passage_time = itinerary.waypoints_with_times(time)[index_of_departure].last

      # #########################################################################

      # FIXME: compatible : -+ 1/2 heure de wish_departure_time
      # FIXME: classé par éloignement de l'heure désirée

      # on part du principe que whish_departure_time : w- et w+ (bornes)

      whish_time = extract_utc_time(whish_departure_time.utc)

      whish_time_min = whish_time - 30.minutes
      whish_time_max = whish_time + 30.minutes

      min_time = extract_utc_time(waypoint_passage_time) - time_delta.minutes
      max_time = extract_utc_time(waypoint_passage_time) + time_delta.minutes
      
      compatible_departure = (min_time >= whish_time_min && min_time <= whish_time_max) || (max_time >= whish_time_min && max_time <= whish_time_max)

      return compatible_departure

      # #########################################################################

      # compatible_departure = (extract_utc_time(whish_departure_time.utc) <= (extract_utc_time(waypoint_passage_time) + time_delta.minutes)) && (extract_utc_time(whish_departure_time.utc) >= (extract_utc_time(waypoint_passage_time) - time_delta.minutes))
      # return compatible_departure
    end

    def index_of_passage(passage_waypoint)
      distances_and_indexes = []

      itinerary.waypoints.each_with_index do |waypoint, index|
        processed_distance = waypoint.distance_from(passage_waypoint).to_f + 1,6

        if processed_distance <= detour_kilometers
          distances_and_indexes << [processed_distance, index]
        end
      end

      return distances_and_indexes.any? ? distances_and_indexes.sort.first.last : nil
    end

    def theorical_intinerary
      @theorical_intinerary ||= GeoProcessService.new.theorical_itinerary(from, to)
    end

    def osrm_itinerary
      # !!! appel API
      @osrm_itinerary ||= GeoProcessService.new.osrm_itinerary(from, to)
    end

    def itinerary
      # FIXME: probleme de perf quand trop de points
      return @itinerary if @itinerary
      wp = []
      wp << from
      wp = wp + get_itinerary_from_waypoints
      wp << to
      @itinerary = Web::Itinerary.new( { waypoints: wp })
      return @itinerary

      #@itinerary ||= theorical_intinerary
    end

    def compatible_dow?(day_of_week)
      compatible_dow = true

      if day_of_week && day_of_week.any? 
        unless (day_of_week & (dow ? dow : [])).any? 
          compatible_dow = false
        end 
      end

      return compatible_dow
    end

    def detour_kilometers
      # [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 13, 15, 20, 22, 26, 27, 30, 60, 120, 240, 300, 360, 420, 480, 540, 600, 660, 900, 1140]
      borned_detour_delta = detour_delta
      borned_detour_delta = 30 if borned_detour_delta > 30

      # detour_delta : approx km detour (A/R point detour) - décorellée des temps de passage
      detour_commuted = (borned_detour_delta.to_f * (Web::Itinerary::SPEED_AVERAGE.to_f/60.to_f).to_f) / 2 
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

    def extract_utc_time(utc_time)
      utc_time.to_s.split(' ')[1].to_time.utc
    end

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

      @filtered_waypoints = JSON.parse(waypoints)

      if @filtered_waypoints.count > 30
        if @filtered_waypoints.count < 100
          @filtered_waypoints = @filtered_waypoints.each_slice(10).map(&:last)
        elsif @filtered_waypoints.count < 100
          @filtered_waypoints = @filtered_waypoints.each_slice(20).map(&:last)
        elsif @filtered_waypoints.count < 200
          @filtered_waypoints = @filtered_waypoints.each_slice(30).map(&:last)
        elsif @filtered_waypoints.count < 300
          @filtered_waypoints = @filtered_waypoints.each_slice(40).map(&:last)
        elsif @filtered_waypoints.count < 400
          @filtered_waypoints = @filtered_waypoints.each_slice(50).map(&:last)
        elsif @filtered_waypoints.count < 500
          @filtered_waypoints = @filtered_waypoints.each_slice(60).map(&:last)
        elsif @filtered_waypoints.count < 600
          @filtered_waypoints = @filtered_waypoints.each_slice(70).map(&:last)
        elsif @filtered_waypoints.count < 700
          @filtered_waypoints = @filtered_waypoints.each_slice(80).map(&:last)
        elsif @filtered_waypoints.count < 800
          @filtered_waypoints = @filtered_waypoints.each_slice(90).map(&:last)
        elsif @filtered_waypoints.count < 900
          @filtered_waypoints = @filtered_waypoints.each_slice(100).map(&:last)
        elsif @filtered_waypoints.count >= 900
          @filtered_waypoints = @filtered_waypoints.each_slice(110).map(&:last)
        end
      else
        @filtered_waypoints = @filtered_waypoints.each_slice(3).map(&:last)
      end

      return @filtered_waypoints
    end
  end
end