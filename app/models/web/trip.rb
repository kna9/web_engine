module Web
  class Trip < ActiveRecord::Base
    include Concerns::HasSiSynchronization
    
    # FIXME : un peu de copier coller pour ces methodes a supprimer...
    # FIXME : extraire la config dans un fichier ou aller chercher la config du SI
    def estimated_waiting_time(dow, hour)
      waiting_time = times[dow.to_s][hour]

      if waiting_time.nil? || waiting_time == -1 || waiting_time > 3600
        3600
      else
        waiting_time
      end
    end

    # FIXME : un peu de copier coller pour ces methodes a supprimer...
    # FIXME : extraire la config dans un fichier ou aller chercher la config du SI
    def estimated_flow(dow, hour)
      flow[dow.to_s][hour]
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
