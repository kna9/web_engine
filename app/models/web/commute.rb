module Web
  # Web::Destination.by_distance(:origin => [49.147956, 1.994782]).first

  class Commute < ActiveRecord::Base
    SPEED_AVERAGE = 50
    KM_DETOUR     = 5

    include Concerns::HasSiSynchronization

    def user
      Web::User.where(id: user_id).first
    end

    def detours
      detours = []
      db_detours_ids.each do |detour_id|
        detours << Web::Destination.where(id: detour_id).first
      end

      detours
    end

    def db_detours_ids
      Web::DbCommuteDestination.where(commute_id: id).map(&:detour_id) # self.detours.to_a.map(&:id)
    end

    def stations
      stations = []
      db_stations_ids.each do |station_id|
        stations << Web::Location.where(id: station_id).first
      end

      stations
    end

    def db_stations_ids
      Web::DbCommuteLocation.where(commute_id: id).map(&:station_id) #self.stations.to_a.map(&:id)
    end

    def start
      Web::Destination.where(id: start_id).first
    end

    def end
      Web::Destination.where(id: end_id).first
    end

    def name
      "#{self.start.name} > #{self.end.name}"
    end

    # def db_class
    #   Web::Commute.first(d: self.id)
    # end

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
      ['14:00', '14:15'], ['14:15', '14:30'], ['14:30', '14:45'], ['14:45', '15:00'], ['15:00', '15:15'], ['15:15', '15:30'], ['15:30', '15:45'], ['15:45', '16:00'],      ['16:00', '16:15'], ['16:15', '16:30'], ['16:30', '16:45'], ['16:45', '17:00'], ['17:00', '17:15'], ['17:15', '17:30'], ['17:30', '17:45'], ['17:45', '18:00'],
      ['18:00', '18:15'], ['18:15', '18:30'], ['18:30', '18:45'], ['18:45', '19:00'], ['19:00', '19:15'], ['19:15', '19:30'], ['19:30', '19:45'], ['19:45', '20:00'],
      ['20:00', '20:15'], ['20:15', '20:30'], ['20:30', '20:45'], ['20:45', '21:00'], ['21:00', '21:15'], ['21:15', '21:30'], ['21:30', '21:45'], ['21:45', '22:00'],
      ['22:00', '22:15'], ['22:15', '22:30'], ['22:30', '22:45'], ['22:45', '23:00'], ['23:00', '23:15'], ['23:15', '23:30'], ['23:30', '23:45'], ['23:45', '0:00']
    ]

    # def time
    #   super.utc.strftime("%H:%M")
    # end

    def time_engagement
      ((time2 - time1) / 60).to_i
    end

    def passage_time_engagement(location)
      ((passage_time2(location) - passage_time1(location)) / 60).to_i
    end

    def time1
      time - time_delta.minutes
    end

    def time2
      time + time_delta.minutes
    end

    def passage_time1(location) 
      passage_time_to_station(location) - time_delta.minutes
    end

    def passage_time2(location)
      passage_time_to_station(location) + time_delta.minutes
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

    def display_passage_time(location)
      if passage_time_to_station(location)
        formated_time(passage_time_to_station(location)) 
      end
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

    def display_departure_time
      formated_time(time)   
    end

    def display_departure_time_min
      departure_time_min = time1
      formated_time(departure_time_min)   
    end

    def display_departure_time_max
      departure_time_max = time2
      formated_time(departure_time_max)   
    end

    def formated_time(param_time)
      param_time.to_s.split(' ')[1].split(':')[0..1].join('H').gsub('H00','H')
    end

    def self.get_commutes(args = {})
      location       = args[:location]
      destination    = args[:destination]
      day_of_week    = args[:dow]
      departure_time = args[:time]

      departure_time = departure_time.to_time if departure_time

      return [] unless location
      return [] unless destination

      results = []

      pre_results = []
      Web::Commute.all.each do |commute|
        pre_results << commute if commute.compatible_dow?(day_of_week)
      end

      pre_results.each do |commute|
        commute_ok = false
        commute_ok = true if commute.passage_time_to_station(location) && commute.compatible(location, destination)
        
        passage_time1 = commute.time - commute.time_delta.minutes
        passage_time2 = commute.time + commute.time_delta.minutes

        if commute.from && departure_time && passage_time1 && passage_time2
          dt = departure_time.to_s.split(" ")[1].to_time
          t1 = passage_time1.to_s.split(" ")[1].to_time
          t2 = passage_time2.to_s.split(" ")[1].to_time
          commute_ok = false if dt <  t1 || dt > t2
        end

        results << commute if commute_ok
      end

      return results
    end

    #    def arrival_compatible(arrival, detour_km = KM_DETOUR)
    #      # theorical_waypoints.reverse_each do |commute_waypoint|
    #      #   distance_from_waypoint_to_arrival_wich = commute_waypoint.distance_from(arrival).to_f 
    #
    #      #   return true if distance_from_waypoint_to_arrival_wich <= detour_km
    #      # end
    #
    #      # return false 
    #      nw =  get_near_waypoint(arrival, detour_km = KM_DETOUR)
    #
    #      if nw
    #        if nw.distance_from(from).to_f <= KM_DETOUR
    #          return false
    #        else
    #          return true
    #        end
    #      else
    #        return false
    #      end
    #    end


    def compatible(departure, arrival, detour_km = KM_DETOUR)
      commute_direction = angle_to_direction(from.heading_to(to))
      whish_direction   = angle_to_direction(departure.heading_to(arrival))

      commute_distance = to.distance_from(from).to_f
      wish_distance    = arrival.distance_from(departure).to_f

      # FIXME: bug eventuel: sud : possibilité compatible sud ouest et sud est : idem pour toutes directions 'pures'
      if commute_direction == whish_direction && commute_distance >= wish_distance
        return true
      else
        return false
      end
    end

    def angle_to_direction(angle)
      direction = ""

      if angle == 0
        direction = "N"
      elsif angle > 0 && angle < 90
        direction = "NE"
      elsif angle == 90
        direction = "E"
      elsif angle > 90 && angle < 180
        direction = "SE"
      elsif angle == 180
        direction = "S"
      elsif angle > 180 && angle < 270
        direction = "SO"
      elsif angle == 270
        direction = "O" 
      elsif angle > 270 && angle < 360
        direction = "NO" 
      end

      return direction
    end

    def get_near_waypoint(arrival, detour_km = KM_DETOUR)
      theorical_waypoints.reverse_each do |commute_waypoint|
        distance_from_waypoint_to_arrival_wich = commute_waypoint.distance_from(arrival).to_f 

        return commute_waypoint if distance_from_waypoint_to_arrival_wich <= detour_km
      end

      return nil 
    end

    def convert_coordinates_array_to_waypoints_array(coordinates_array)
      waypoints_array = []
        coordinates_array.each do |coordinates_string|
        waypoints_array << Web::Destination.new(lat: coordinates_string.split(',').first, long: coordinates_string.split(',').last)
      end

      return waypoints_array
    end

    def passage_time_to_station(location, detour_km = KM_DETOUR, average_speed= SPEED_AVERAGE, debug = false)
      key_cash = "#{location.id.to_s}-#{detour_km}-#{average_speed}"
      @estimated_time_of_passage = {} unless @estimated_time_of_passage

      return @estimated_time_of_passage[key_cash] if  @estimated_time_of_passage && @estimated_time_of_passage[key_cash]
      
      estimated_time =  time_from_departure_to_station(location, detour_km, average_speed)
      
      @estimated_time_of_passage[key_cash] = nil unless estimated_time
      @estimated_time_of_passage[key_cash] = nil unless time
      
      @estimated_time_of_passage[key_cash] = time + estimated_time.hours if estimated_time && time
      
      return @estimated_time_of_passage[key_cash]
    end

    def time_from_departure_to_station(location, detour_km = KM_DETOUR, average_speed= SPEED_AVERAGE)
      estimated_distance = distance_from_departure_to_station(location, detour_km)

      return nil unless estimated_distance
      
      estimated_time = estimated_distance / average_speed

      return estimated_time
    end

    def distance_from_departure_to_station(location, detour_km = KM_DETOUR)
      array_points_distance = []

      theorical_waypoints.each do |theorical_waypoint|
        theorical_distance = theorical_waypoint.distance_from(location).to_f 

        if (theorical_distance <= detour_km)
          array_points_distance << [ theorical_distance, theorical_waypoint ]
        end
      end

      array_points_distance   = array_points_distance.sort { |a, b| a.first <=> b.first }
      near_point_and_distance = array_points_distance.first

      return nil unless near_point_and_distance

      near_point_distance_from_station = near_point_and_distance.first
      near_point_from_station          = near_point_and_distance.last

      distance_from_departure_to_waypoint = near_point_from_station.distance_from(from)

      distance_from_departure_to_station  = distance_from_departure_to_waypoint + near_point_distance_from_station

      return distance_from_departure_to_station
    end

    def theorical_waypoints
      return @theorical_waypoints if @theorical_waypoints

      @theorical_waypoints   = []
      @theorical_waypoints << from

      # FIXME: peut être le vrai trajet mais très long a calculer (a stocker)
      #route_waypoints = OSRM.route("#{from.lat},#{from.long}", "#{to.lat},#{to.long}").geometry
      #route_waypoints.each do |route_waypoint|
      #  @theorical_waypoints << Web::Destination.new(lat: route_waypoint.first, long: route_waypoint.last)
      #end
   
      theorical_coordinates = GeoProcessService.new.get_waypoints(from.lat, from.long, to.lat, to.long)    
      theorical_coordinates.each do |coordinates_string|
        @theorical_waypoints << Web::Destination.new(lat: coordinates_string.split(',').first, long: coordinates_string.split(',').last)
      end

      @theorical_waypoints << to

      return @theorical_waypoints
    end

    # FIXME : short_time : sortir dans un helper
    def short_time(real_time)
      (real_time && real_time.to_time) ? real_time.strftime("%H:%M") : "00:00"
    end

    def compatible_departure_time?(departure_time)
      compatible_departure_time = true
      min_time, max_time        = get_min_and_max_time

      # "08:30".to_time.utc.strftime("%H%M%S%N")

      return false unless departure_time

      # FIXME : ICI ON PEUT REGLER SECONDES DELTA EN MINUTES SI PAS ASSEZ DE RESULT / min_time = si_time-time_delta.minutes / max_time = si_time + time_delta.minutes
  
      if process_converted_time < min_time || process_converted_time > max_time
        compatible_departure_time = false
      end

      return compatible_departure_time
    end

    def get_min_and_max_time
      si_time = time # "08:30".to_time
      if si_time
        si_time = si_time.to_time
      end
  
      time_delta = time_delta
      time_delta = 0 unless time_delta
      time_delta = time_delta.to_i

      min_time = si_time - time_delta.seconds
      max_time = si_time + time_delta.seconds 

      [convert_time(min_time), convert_time(max_time)]
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

    def compatible_dow?(day_of_week)
      compatible_dow = true

      if day_of_week && day_of_week.any? 
        unless (day_of_week & (dow ? dow : [])).any? 
          compatible_dow = false
        end 
      end

      return compatible_dow
    end
  end
end