# coding: utf-8

class Numeric
  def to_rad
    self * Math::PI / 180
  end
  def to_deg
    self * 180 / Math::PI
  end
end

include Math

class GeoProcessService
  RVAL  = 6371.0
  DIST  = 1 

  def initialize

  end

  def waypoint(φ1, λ1, θ, d)
    φ2 = asin( sin(φ1) * cos(d/RVAL) + cos(φ1) * sin(d/RVAL) * cos(θ) )
    λ2 = λ1 + atan2( sin(θ) * sin(d/RVAL) * cos(φ1), cos(d/RVAL) - sin(φ1) * sin(φ2) )
    λ2 = (λ2 + 3 * Math::PI) % (2 * Math::PI) - Math::PI # normalise to -180..+180°

    [φ2, λ2]
  end

  def get_waypoints(lat1, long1, lat2, long2)
    φ1, λ1 = lat1.to_rad, long1.to_rad
    φ2, λ2 = lat2.to_rad, long2.to_rad

    d = RVAL * acos( sin(φ1) * sin(φ2) + cos(φ1) * cos(φ2) * cos(λ2 - λ1) )
    θ = atan2( sin(λ2 - λ1) * cos(φ2), cos(φ1) * sin(φ2) - sin(φ1) * cos(φ2) * cos(λ2 - λ1) )

    waypoints = (0..d).step(DIST).map { |d| waypoint(φ1, λ1, θ, d) }

    markers = waypoints.map { |φ, λ| "#{φ.to_deg},#{λ.to_deg}" }.join("|")
    markers = waypoints.map { |φ, λ| "#{φ.to_deg},#{λ.to_deg}" }

    return markers
  end

  def itinerary(departure, arrival, method_name)
    markers = if method_name == :theorical
      get_waypoints(departure.lat, departure.long, arrival.lat, arrival.long)
    elsif method_name == :osrm 
      OSRM.route("#{departure.lat},#{departure.long}", "#{arrival.lat},#{arrival.long}").geometry
    else
      []
    end

    waypoints = []
    waypoints << departure 

    markers.each do |marker|
      waypoints << Web::Destination.new(extract_coordinates_from_marker(marker, method_name))
    end

    waypoints << arrival

    return Web::Itinerary.new( { waypoints: waypoints })
  end

  def theorical_itinerary(departure, arrival)
     itinerary(departure, arrival, :theorical)
  end

  def osrm_itinerary(departure, arrival)
    itinerary(departure, arrival, :osrm)
  end

  private

  def extract_coordinates_from_marker(marker, method_name)
    coordinates_form = if method_name == :theorical
      { lat: marker.split(',').first, long: marker.split(',').last }
    elsif method_name == :osrm 
      { lat: marker.first, long: marker.last }
    else
      {}
    end

    return coordinates_form
  end
end
