module Web
  class Day < ActiveRecord::Base
    # FIXME : intérêt de la synchronisation??
    SI_MANDATORY_FIELDS = []
    SI_FIELDS_MAPPING   = {}

    # include Concerns::HasPersistantSynchronizationWithSiModel
    include Concerns::HasNonPersistantSynchronizationWithSiModel

    self.table_name = 'web_days'

    # has_and_belongs_to_many :commutes, association_foreign_key: 'web_commute_id', foreign_key: 'web_day_id'

    def si_attributes
      { the_attributes_are: 'LES ATTRIBUTES DU SI POUR WEB::DAY' }
    end
  end
end

