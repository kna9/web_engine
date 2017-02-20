DataMapper.setup(:default, "postgres://db-si:efe9Quah@127.0.0.1/ecov-staging")
# FIXME : ajouter un /current/ en prod...

require_relative '/home/vagrant/si/db/models'
#require_relative '/home/vagrant/si/db/models'

Object.const_set('SI', Module.new()) 

DB.constants.each do |datamaper_class_name|
  klass = Class.new(ActiveRecord::Base) do   
    define_method 'save' do
      datamaper_class = eval("DB::#{datamaper_class_name.to_s}")

      if new_record?
        datamaper_instance = datamaper_class.new(attributes)
        retour = datamaper_instance.save

        unless retour
          errors.add(:id, :blank, message: "Error from Datamaper validations: #{datamaper_instance.errors.values.join(' / ')}")
          return retour
        end
      else
        datamaper_instance = datamaper_class.first(id: id)
        retour = datamaper_instance.update(attributes)

        unless retour
          errors.add(:id, :blank, message: "Error from Datamaper validations: #{datamaper_instance.errors.values.join(' / ')}")
          return retour
        end
      end

      #super()
      return true
    end

    # FIXME : solution plus élégante a trouver pour mapping des relations

    if datamaper_class_name.to_s == 'Commute'
      define_method 'detours' do
        detours = []

        db_detours_ids.each do |detour_id|
          detours << Web::Destination.find(detour_id)
        end

        detours
      end

      define_method 'stations' do
        stations = []

        db_stations_ids.each do |station_id|
          stations << Web::Location.find(station_id)
        end

        stations
      end

      define_method 'start' do
        Web::Destination.find(start_id)
      end

      define_method 'end' do
        Web::Destination.find(end_id)
      end

      define_method 'user' do
        Web::User.find(user_id)
      end

      define_method 'db_class' do
        DB::Commute.first(id: self.id)
      end

      define_method 'db_detours_ids' do
        db_class.detours.to_a.map(&:id)
      end

      define_method 'db_stations_ids' do
        db_class.stations.to_a.map(&:id)
      end
    end
  end

  SI.const_set(datamaper_class_name.to_s.classify, klass)   
end
