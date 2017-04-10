module Web
  class Itinerary
    SPEED_AVERAGE = 50
    KM_DETOUR_MIN = 1

    attr_accessor :waypoints

    def initialize(arguments)
      @waypoints   = arguments[:waypoints] if arguments[:waypoints]
    end

    def waypoints_with_times(departure_time)
      waypoints_with_times = []

      waypoints_with_distance_from_departure.each do |waypoint_with_distance_from_departure|
        waypoints_with_times << [ waypoint_with_distance_from_departure.first, estimated_time_from_departure(departure_time, waypoint_with_distance_from_departure.last) ]
      end

      return waypoints_with_times
    end


    def waypoints_with_distance_from_departure
      @waypoints_with_distance_from_departure ||= get_waypoints_with_distance_from_departure
    end

    private

    def get_waypoints_with_distance_from_departure
      # FIXME : entre chaques points en vol d'oiseau

      waypoints_with_distance = []

      waypoints.each_with_index do |waypoint, index|
        waypoint_with_distance = []
        waypoint_with_distance << waypoint

        distance_from_origin_to_waypoint = 0

        (0..index).each do |i|
          distance_from_origin_to_waypoint = if i == 0
            0
          else
            distance_from_origin_to_waypoint + (waypoints[i - 1].distance_from(waypoints[i]).to_f * 1,6)
          end   
        end

        waypoint_with_distance << distance_from_origin_to_waypoint

        waypoints_with_distance << waypoint_with_distance
      end

      return waypoints_with_distance
    end

    def estimated_time_from_departure(origin_time, distance_from_origin)
      return origin_time if distance_from_origin == 0

      time_from_origin = distance_from_origin / SPEED_AVERAGE
      estimated_time   = origin_time + time_from_origin.hours

      return estimated_time
    end
  end
end