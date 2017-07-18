class DriverEquivalantProcessService
  def initialize(time, delta)
    @time           = time
    @converted_time = @time.utc.strftime("%H:%M").to_time
    @delta          = delta
    @driver_eq      = {}

    @driver_equivalants_per_quaters = {}
  end

  def perform
    process_driver_equivalant_per_quarters
  end

  def driver_equivalant_per_quarters
    @driver_equivalants_per_quaters
  end

  def driver_equivalant_sum_for_day
    driver_equivalant_day_sum = 0.0

    @driver_equivalants_per_quaters.each do |key, driver_equivalant_value|
      driver_equivalant_day_sum = driver_equivalant_day_sum + driver_equivalant_value
    end

    driver_equivalant_day_sum
  end

  private

  def process_driver_equivalant_per_quarters # FIXME : change ec >> driver_equivalant
    @driver_equivalants_per_quaters = {}

    quarters_times_intervals.each do |t|
      @driver_equivalants_per_quaters[t] = process_driver_equivalant(t.first.to_time, t.last.to_time)
    end
  end

  def process_driver_equivalant(time_min, time_max)
    (time_min..time_max).include?(@converted_time) ? driver_equivalant_value : 0
  end

  def driver_equivalant_value
    probability, weighting = if time_engagement > 0 && time_engagement <= 15
      [ 1, 1 ]
    elsif time_engagement > 15 && time_engagement <= 30
      [ 0.7, 0.5 ]
    elsif time_engagement > 30 && time_engagement <= 60
      [ 0.5, 0.25 ]
    else
      [ 0, 0 ]
    end

    probability * weighting
  end

  def time_engagement
    ((time2 - time1) / 60).to_i # FIXME: in seconds...???
  end

  def time1
    @time - @delta.minutes
  end

  def time2
    @time + @delta.minutes
  end

  def quarters_times_intervals
    (0..23).each.flat_map { |hour| [["#{hour}:00", "#{hour}:15"], ["#{hour}:15", "#{hour}:30"], ["#{hour}:30", "#{hour}:45"], ["#{hour}:45", "#{ hour+1 < 24 ? hour+1 : 0}:00"]] }
  end
end
