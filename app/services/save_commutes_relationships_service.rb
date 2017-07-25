class SaveCommutesRelationshipsService
  RELATIONSHIP_DATABASE_TABLES = { detours: 'db_commute_destinations', stations: 'db_commute_locations' }
  STATEMENT_NAMES = { detours: 'del_commute_destination', stations: 'del_commute_location' }

  def initialize(arguments)
    @user_id       = arguments[:user_id]
    @commute_id    = arguments[:commute_id]
    @entities_type = arguments[:entities_type]
    @commute       = arguments[:commute]
  end

  def clear_and_save_entities
    return unless @user_id
    return unless @commute_id
    return unless @entities_type
    return unless @commute

    clear_entities

    entities.each do |entity|
      entity_relationship_to_save = new_entity_relationship(entity)
      begin
        entity_relationship_to_save.save
      rescue
        true
      end
    end
  end

  def save_all_commute_locations
    return unless @commute
    Web::Location.all.each do |location|
      save_commute_location_link(location)
    end
  end

  private

  def save_commute_location_link(location)
    existing_record = ::CommutesLocation.where(commute_id: @commute.id, location_id: location.id).first

    if @commute.is_compatible_commute(location)
      unless existing_record
        commutes_location = ::CommutesLocation.new(commute_id: @commute.id, location_id: location.id)
        commutes_location.save
      end
    else
      if existing_record
        existing_record.delete
      end
    end
  end

  def entities
    @commute.send(@entities_type)
  end

  def new_entity_relationship(entity)
    if @entities_type == :detours
      ::DbCommuteDestination.new(commute_user_id: @user_id, commute_id: @commute_id, detour_id: entity.id)
    elsif @entities_type == :stations
      ::DbCommuteLocation.new(commute_user_id: @user_id, commute_id: @commute_id, station_id: entity.id)
    end
  end

  def clear_entities
    # :detours / :stations
    return unless @commute_id

    connection = ActiveRecord::Base.connection.raw_connection

    begin
      connection.prepare(statement_name(@entities_type), clear_entities_sql(@entities_type))
    rescue PG::DuplicatePstatement => e
    end

    statement = connection.exec_prepared(statement_name(@entities_type), [ @user_id, @commute_id ])
  end

  def statement_name(entities_type)
    STATEMENT_NAMES[entities_type]
  end

  def clear_entities_sql(entities_type)
    "delete from #{RELATIONSHIP_DATABASE_TABLES[entities_type]} where commute_user_id=$1 and commute_id=$2"
  end
end
