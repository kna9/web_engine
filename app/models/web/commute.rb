module Web
  class Commute < SI::Commute
    alias_method :from, :start
    alias_method :from_city, :start
    alias_method :to, :end
    alias_method :to_city, :end

    QUARTERS =  [
        ['0:00', '0:15'],
        ['0:15', '0:30'],
        ['0:30', '0:45'],
        ['0:45', '1:00'],
        ['1:00', '1:15'],
        ['1:15', '1:30'],
        ['1:30', '1:45'],
        ['1:45', '2:00'],
        ['2:00', '2:15'],
        ['2:15', '2:30'],
        ['2:30', '2:45'],
        ['2:45', '3:00'],
        ['3:00', '3:15'],
        ['3:15', '3:30'],
        ['3:30', '3:45'],
        ['3:45', '4:00'],
        ['4:00', '4:15'],
        ['4:15', '4:30'],
        ['4:30', '4:45'],
        ['4:45', '5:00'],
        ['5:00', '5:15'],
        ['5:15', '5:30'],
        ['5:30', '5:45'],
        ['5:45', '6:00'],
        ['6:00', '6:15'],
        ['6:15', '6:30'],
        ['6:30', '6:45'],
        ['6:45', '7:00'],
        ['7:00', '7:15'],
        ['7:15', '7:30'],
        ['7:30', '7:45'],
        ['7:45', '8:00'],
        ['8:00', '8:15'],
        ['8:15', '8:30'],
        ['8:30', '8:45'],
        ['8:45', '9:00'],
        ['9:00', '9:15'],
        ['9:15', '9:30'],
        ['9:30', '9:45'],
        ['9:45', '10:00'],
        ['10:00', '11:15'],
        ['10:15', '10:30'],
        ['10:30', '10:45'],
        ['10:45', '11:00'],
        ['11:00', '11:15'],
        ['11:15', '11:30'],
        ['11:30', '11:45'],
        ['11:45', '12:00'],
        ['12:00', '12:15'],
        ['12:15', '12:30'],
        ['12:30', '12:45'],
        ['12:45', '13:00'],
        ['13:00', '13:15'],
        ['13:15', '13:30'],
        ['13:30', '13:45'],
        ['13:45', '14:00'],
        ['14:00', '14:15'],
        ['14:15', '14:30'],
        ['14:30', '14:45'],
        ['14:45', '15:00'],
        ['15:00', '15:15'],
        ['15:15', '15:30'],
        ['15:30', '15:45'],
        ['15:45', '16:00'],
        ['16:00', '16:15'],
        ['16:15', '16:30'],
        ['16:30', '16:45'],
        ['16:45', '17:00'],
        ['17:00', '17:15'],
        ['17:15', '17:30'],
        ['17:30', '17:45'],
        ['17:45', '18:00'],
        ['18:00', '18:15'],
        ['18:15', '18:30'],
        ['18:30', '18:45'],
        ['18:45', '19:00'],
        ['19:00', '19:15'],
        ['19:15', '19:30'],
        ['19:30', '19:45'],
        ['19:45', '20:00'],
        ['20:00', '20:15'],
        ['20:15', '20:30'],
        ['20:30', '20:45'],
        ['20:45', '21:00'],
        ['21:00', '21:15'],
        ['21:15', '21:30'],
        ['21:30', '21:45'],
        ['21:45', '22:00'],
        ['22:00', '22:15'],
        ['22:15', '22:30'],
        ['22:30', '22:45'],
        ['22:45', '23:00'],
        ['23:00', '23:15'],
        ['23:15', '23:30'],
        ['23:30', '23:45'],
        ['23:45', '0:00']
      ]

    def time_engagement
      ((time2 - time1) / 60).to_i
    end

    def time1
      time-time_delta.minutes
    end

    def time2
      time + time_delta.minutes
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
      choosen_web_station = args[:location]
    
      return self.all unless choosen_web_station
    
      day_of_week    = args[:dow]
      departure_time = args[:time]
    
      km_detour_approximation = 1 # FIXME: depends on detour declared (en temps donc simuler vitesse)
    
      near_choosen_location_stations = Web::Location.within(km_detour_approximation, origin: choosen_web_station)
      near_choosen_location_steps    = Web::Destination.within(km_detour_approximation, origin: choosen_web_station)
    
      if args[:destination]
        choosen_web_destination           = args[:destination]
        near_choosen_destination_stations = Web::Location.within(km_detour_approximation, origin: choosen_web_destination)
        near_choosen_destination_steps    = Web::Destination.within(km_detour_approximation, origin: choosen_web_destination)
      end
    
      near_stations     = (near_choosen_location_stations.to_a + near_choosen_destination_stations.to_a).uniq
      near_steps        = (near_choosen_location_steps.to_a + near_choosen_destination_steps).uniq
      near_stations_ids = near_stations.map(&:id)
      near_steps_ids    = near_steps.map(&:id)
      acm               = []
          
      Web::Commute.all.each do |commute|
        commute_ok = false
    
        if near_steps_ids.include?(commute.start_id) || near_steps_ids.include?(commute.end_id) || (commute.detours.map(&:id) & near_steps_ids).any?
          commute_ok = true 
        end
    
        if (commute.stations.map(&:id) & near_stations_ids).any?
          commute_ok = true 
        end
    
        # --exclusions conditions with day_of_week || departure_time
    
        if day_of_week && day_of_week.any? 
          unless (day_of_week & commute.dow).any? # [0,1,2,3]
            commute_ok = false
          end 
        end
    
        if departure_time
          si_time = commute.time # "08:30".to_time
          if si_time
            si_time = si_time.to_time
          end
    
          time_delta = commute.time_delta
          time_delta = 0 unless time_delta
          time_delta = time_delta.to_i
          min_time = si_time-time_delta.seconds
          max_time = si_time + time_delta.seconds 

          # FIXME : ICI ON PEUT REGLER SECONDES DELTA EN MINUTES SI PAS ASSEZ DE RESULT
          # min_time = si_time-time_delta.minutes
          # max_time = si_time + time_delta.minutes
    
          if departure_time.utc.strftime("%H%M%S%N") < min_time.utc.strftime("%H%M%S%N") || departure_time.utc.strftime("%H%M%S%N") > max_time.utc.strftime("%H%M%S%N")
            commute_ok = false
          end
        end
    
        if commute_ok == true
          acm << commute
        end
      end
    
      return acm
    end

    def self.create_all_commute_steps_report
      
      # Web::CommutesReport::WebCommutesRepor
      data_report = {}

      secure_key = Web::CommutesReport.initialize_report('Tous les trajets déclarés')

      self.all.each do |web_commute|
        web_commute.steps_with_times.each do |step|
          if step.any? && step.count == 2 && step.first.first && step.last.first
            t1 = step.first.last
            t2 = step.last.last

            report_key = "#{step.first.first.id}_#{step.last.first.id}_#{t1}_#{t2}"

            if data_report[report_key] 
              data_report[report_key][0] = data_report[report_key][0].to_i + 1
            else
              data_report[report_key] = [1, [step.first.first, step.first.last], [step.last.first, step.last.last]]
            end
          end
        end
      end

      data_report.each do |key, value|
        if value && value.any? && value[0] && value[1] && value[1].any? && value[1][0] && value[1][1]&& value[2] && value[2].any? && value[2][0] && value[2][1]
          wc = CommutesReport.create(
            report_key: secure_key, 
            quantity:   value[0],
            from_id:    value[1][0].id, 
            from_name:  value[1][0].name, 
            from_lat:   value[1][0].lat, 
            from_lng:   value[1][0].lng, 
            from_time:  value[1][1], 
            to_id:      value[2][0].id, 
            to_name:    value[2][0].name, 
            to_lat:     value[2][0].lat, 
            to_lng:     value[2][0].lng,
            to_time:    value[2][1]
          )
        end
      end

      secure_key
    end

    def steps_with_times(speed_average = 90)
      steps_with_times = []

      old_time = self.time ? self.time : '00:00'.to_time
      old_city = self.from_city
      detours  = self.detours

      begin
        part_cities  = []

        part_cities << [ old_city, short_time(old_time) ]

        detours.each do |detour_city|
          new_time = short_time(old_time).to_time + detour_city.time_from(old_city, speed_average)

          part_cities << [ detour_city, short_time(new_time)]

          steps_with_times << part_cities

          old_time = new_time
          old_city = detour_city

          part_cities = []
          part_cities << [ detour_city, short_time(old_time)]
        end

        new_time = short_time(old_time).to_time + self.to_city.time_from(old_city, speed_average)
        part_cities << [ self.to_city, short_time(new_time) ]

        steps_with_times << part_cities
      rescue
        steps_with_times = if self.from_city && self.to_city
          [
            [self.from_city, short_time(old_time)], 
            [self.to_city, short_time(short_time(old_time).to_time + self.to_city.time_from(self.from_city, speed_average))] 
          ]
        else 
          []
        end
      end


      steps_with_times
    end

    def suggested_web_stations(km_zone = 3)
      compatible_web_stations(km_zone)-self.stations
    end

    def compatible_web_stations(km_zone = 3)
      compatible_web_stations = []

      Location.all.each do |web_station|
        self.detours.each do |step|
          if step.distance_from(web_station).to_f <= km_zone.to_f
            compatible_web_stations << web_station unless compatible_web_stations.include?(web_station)
          end
        end
      end

      compatible_web_stations
    end

    private

    # FIXME : short_time : sortir dans un helper

    def short_time(real_time)
      (real_time && real_time.to_time) ? real_time.strftime("%H:%M") : "00:00"
    end
  end
end