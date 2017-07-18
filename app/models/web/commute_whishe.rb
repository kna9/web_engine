module Web
  class CommuteWhishe < ActiveRecord::Base
    WHISHE_STATUSES        = { created: 1, confirmed: 3, deleted: -1 }
    COMMUTE_WHISHE_VERSION = 'v3'

    # attr_accessor :confirmed, :version, :search_dtm, :nb_result, :referer, :remote_ip

    after_initialize :new_commute_whish

    validates :selected_date, presence: true
    validates :start_id, presence: true
    validates :end_id, presence: true
    #validates :user_id, presence: true
    validates :from_name, presence: true
    validates :to_name, presence: true
    validates :confirmed, presence: true
    validates :version, presence: true
    # validates :referer, presence: true
    validates :remote_ip, presence: true
    validates :selected_date, presence: true

    def set_nb_results(nb_results)
      self.nb_results = nb_results
    end

    def set_date
      self.search_dtm = DateTime.now.to_s
    end

    def deleted?
      self.confirmed == WHISHE_STATUSES[:deleted]
    end

    def created?
      self.confirmed == WHISHE_STATUSES[:created]
    end

    def set_confirmed
      set_status(:confirmed)
    end

    def set_deleted
      set_status(:deleted)
    end

    def set_created
      set_status(:created)
    end

    private

    def new_commute_whish
      return unless self.new_record?

      set_created
      initialize_version
      set_date
    end

    def set_status(status)
      self.confirmed = WHISHE_STATUSES[status]
    end

    def initialize_status
      set_created unless self.confirmed
    end

    def initialize_version
      self.version = COMMUTE_WHISHE_VERSION unless self.version
    end
  end
end
