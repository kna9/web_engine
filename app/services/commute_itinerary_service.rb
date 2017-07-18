class CommuteItineraryService
  def initialize(from, to, waypoints)
    @from      = from
    @to        = to
    @waypoints = waypoints
  end

  def perform
    Web::Itinerary.new( { waypoints: [@from] + get_itinerary_from_waypoints + [@to] })
  end

  private

  def get_itinerary_from_waypoints
    itinerary_from_waypoints = []

    get_filtered_waypoints.each do |waypoint|
      itinerary_from_waypoints << Web::Destination.new(lat: waypoint.first, long: waypoint.last)
    end

    return itinerary_from_waypoints
  end

  def get_filtered_waypoints
    return @filtered_waypoints if @filtered_waypoints
    return [] if @waypoints.to_s == ''

    @filtered_waypoints = nil

    begin
      @filtered_waypoints = JSON.parse(@waypoints)
    rescue
      @filtered_waypoints = nil
    end

    return [] unless @filtered_waypoints
      
    slice_val = @filtered_waypoints.count > 30 ? (((@filtered_waypoints.count.to_f/100).round+1)*10) : 3

    @filtered_waypoints = @filtered_waypoints.each_slice(slice_val).map(&:last)

    return @filtered_waypoints
  end
end
