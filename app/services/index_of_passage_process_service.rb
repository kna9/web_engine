class IndexOfPassageProcessService
  MILES_PER_KM = 1.6

  def initialize(passage_waypoint, itinerary, detour_delta)
    @passage_waypoint = passage_waypoint
    @itinerary        = itinerary
    @detour_delta     = detour_delta
  end

  def perform
    distances_and_indexes = []

    @itinerary.waypoints.each_with_index do |waypoint, index|
      # FIXME : update geoloc config to get values in kilometers
      processed_distance = waypoint.distance_from(@passage_waypoint).to_f * MILES_PER_KM

      if processed_distance <= detour_kilometers ##
        distances_and_indexes << [processed_distance, index]
      end
    end

    return distances_and_indexes.any? ? distances_and_indexes.sort.first.last : nil
  end

  private

  def detour_kilometers
    limited_detour_delta = @detour_delta
    limited_detour_delta = Web::Commute::DETOUR_DELTA_LIMIT if limited_detour_delta > Web::Commute::DETOUR_DELTA_LIMIT

    detour_commuted = (limited_detour_delta.to_f * (Web::Itinerary::SPEED_AVERAGE.to_f/60.to_f).to_f) / 2 
    detour_min      = Web::Itinerary::KM_DETOUR_MIN.to_f

    detour_kilometers = if detour_commuted <= detour_min
      detour_min
    else
      detour_commuted
    end

    return detour_kilometers
  end
end