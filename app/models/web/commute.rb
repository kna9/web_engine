module Web
  class Commute < ActiveRecord::Base
    SPEED_AVERAGE      = 50
    KM_DETOUR          = 5
    DETOUR_DELTA_LIMIT = 10

    include Concerns::HasSiSynchronization

    def save_all_commute_locations
      SaveCommutesRelationshipsService.new({ commute: self }).save_all_commute_locations
    end

    def save_detours(commute_id)
      SaveCommutesRelationshipsService.new({ user_id: user_id, commute_id: commute_id, entities_type: :detours, commute: self }).clear_and_save_entities
    end

    def save_stations(commute_id)
      SaveCommutesRelationshipsService.new({ user_id: user_id, commute_id: commute_id, entities_type: :stations, commute: self }).clear_and_save_entities
    end

    def compatible_locations
      Web::Location.where(id: CommutesLocation.where(commute_id: id).map(&:location_id))
    end

    def user
      @user ||= Web::User.where(id: user_id).first
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

    def detours 
      @detours ||= Web::Destination.where(id: Web::DbCommuteDestination.where(commute_id: id).map(&:detour_id)).to_a
    end

    def stations
      @stations ||= Web::Location.where(id: Web::DbCommuteLocation.where(commute_id: id).map(&:station_id)).to_a
    end

    alias_method :from, :start
    alias_method :from_city, :start
    alias_method :to, :end
    alias_method :to_city, :end

    # SEARCH ENGINE

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

      Web::Commute.declared_for_dows(whish_days_of_week).each do |commute|
        results << commute if commute.compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time_min, whish_departure_time_max)
      end

      return results
    end

    # PASSAGE CHECK

    def passage_time_to_station(location)
      index_of_passage = index_of_passage(location)

      return false unless index_of_passage

      return itinerary.waypoints_with_times(time)[index_of_passage].last
    end

    def compatible_departure_and_arrival_with_whish_itinerary(whish_itinerary, whish_departure_time_min, whish_departure_time_max)
      index_of_departure = index_of_passage(whish_itinerary.waypoints.first)
      index_of_arrival   = index_of_passage(whish_itinerary.waypoints.last)

      return false unless index_of_departure
      return false unless index_of_arrival
      return false if index_of_departure >= index_of_arrival

      return compatible_departure = compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time_min, whish_departure_time_max) 
    end

    def compatible_departure_with_whish_initerary(index_of_departure, whish_departure_time_min, whish_departure_time_max)
      waypoint_passage_time = itinerary.waypoints_with_times(time)[index_of_departure].last
      # FIXME: sorted by desired time far

      min_time = Web::Commute.extract_utc_time(waypoint_passage_time) - time_delta.minutes
      max_time = Web::Commute.extract_utc_time(waypoint_passage_time) + time_delta.minutes
      
      # compatible_departure = (min_time >= whish_departure_time_min && min_time <= whish_departure_time_max) || (max_time >= whish_departure_time_min && max_time <= whish_departure_time_max)
      compatible_departure = !(max_time < whish_departure_time_min || min_time > whish_departure_time_max)

      return compatible_departure
    end

    def index_of_passage(passage_waypoint)
      IndexOfPassageProcessService.new(passage_waypoint, itinerary, detour_delta).perform
    end

    def is_compatible_commute(location)
      return index_of_passage(location) ? true : false
    end

    # ITINERARIES

    def theorical_itinerary
      @theorical_itinerary ||= GeoProcessService.new.theorical_itinerary(from, to)
    end

    def osrm_itinerary
      @osrm_itinerary ||= GeoProcessService.new.osrm_itinerary(from, to) # FIXME : secure API call
    end

    def itinerary
      @itinerary ||= CommuteItineraryService.new(from, to, waypoints).perform
    end

    # DOW CHECK

    def self.declared_for_dows(days_ids)
      compatible_dow_commutes = []

      Web::Commute.all.each do |commute|
        compatible_dow_commutes << commute if commute.is_declared_for_dows?(days_ids)
      end

      return compatible_dow_commutes
    end

    def is_declared_for_dows?(days_ids)
      days_ids && dow && !(days_ids & dow).empty?
    end

    # DRIVER EQUIVALANT

    def ec # FIXME : change ec >> driver_equivalant
      driver_equivalant_service.driver_equivalant_per_quarters
    end

    def ec_sum # FIXME : change ec >> driver_equivalant
      driver_equivalant_service.driver_equivalant_sum_for_day

      # FIXME : BUG 
      #      Web::Commute.all.each do |c|
      #        puts c.ec.values.uniq.inspect
      #        puts c.ec_sum
      #      end;nil
      #      Web::Commute.order(:id).last.ec.values.uniq
      # >>>>>> TOTAL > 1 ? possible???
    end

    # TIME CONVERSION / FIXME : extract on service util class and presenters

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

    def self.extract_utc_time(utc_time)
      utc_time.to_s.split(' ')[1].to_time.utc
    end

    # FIXME: USED FOR REPORT


    def time_min
      time - time_delta.minutes
    end

    def time_max
      time + time_delta.minutes
    end

    private

    def driver_equivalant_service
      driver_equivalant_process_service = DriverEquivalantProcessService.new(time, time_delta)
      driver_equivalant_process_service.perform

      return driver_equivalant_process_service
    end
  end
end