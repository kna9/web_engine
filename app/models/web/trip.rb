module Web
  class Trip < ActiveRecord::Base
    include Concerns::HasSiSynchronization

    def self.flow_for_location(location, dow = 2)

    end

    def self.max_flow_for_location(location, dow = 2)
    #      all_trips = Web::Trip.where(location_id: location.id)
    #      puts all_trips.count
    #      flws     = []
    #
    #      all_trips.each do |trip|
    #        JSON.parse(trip.flow)[dow.to_s].each do |f|
    #          flws << f.to_f 
    #        end
    #      end
    #
    #      return flws.uniq.map(&:to_f).max
    end
    
    # FIXME : un peu de copier coller pour ces methodes a supprimer...
    # FIXME : extraire la config dans un fichier ou aller chercher la config du SI
    def estimated_waiting_time(dow, hour)
      processed_times = JSON.parse(times) if times

      if processed_times
        waiting_time = processed_times[dow][hour] if processed_times[dow]
        if waiting_time.nil? || waiting_time == -1 || waiting_time > 3600
          3600
        else
          waiting_time
        end
      end
    end


    # FIXME : un peu de copier coller pour ces methodes a supprimer...
    # FIXME : extraire la config dans un fichier ou aller chercher la config du SI
    def estimated_flow(dow, hour)
      # flow[dow.to_s][hour]
      return unless flow
      res_flow = JSON.parse(flow)

      ret = res_flow[dow.to_s][hour].to_i if res_flow && res_flow[dow.to_s]

      return ret
    end


    # FIXME : un peu de copier coller pour ces methodes a supprimer...
    # FIXME : extraire la config dans un fichier ou aller chercher la config du SI
    def price
      gross_price = (distance * 0.12).round(-1).to_i

      if gross_price < 600
        600
      else
        gross_price
      end
    end
  end
end

figures = []
Web::Location.all.each do |l|
  figures << [l.name, Web::Trip.flow_for_location(Web::Location.first, 3)]
end;nil

figures.each do |f|
  puts "#{f.first}  : #{f.last}"
end;nil
