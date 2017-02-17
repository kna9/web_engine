module Web
  class Trip
    SI_MANDATORY_FIELDS = [ :location, :destination ]
    SI_FIELDS_MAPPING   = {
      price:                  :price,
      distance:               :distance,
      flow:                   :flow,
      times:                  :times
    }

    include Concerns::HasNonPersistantSynchronizationWithSiModel

    attr_accessor :location, :destination, :price, :distance, :flow, :times

    def initialize(args = {})
      args.each do |key, value|
      	self.send("#{key}=", value)
      end
    end

    def estimated_waiting_time(dow, hour)
      waiting_time = times[dow.to_s][hour]

      if waiting_time.nil? || waiting_time == -1 || waiting_time > 3600
        3600
      else
        waiting_time
      end
    end

    def estimated_flow(dow, hour)
      flow[dow.to_s][hour]
    end
  end
end
