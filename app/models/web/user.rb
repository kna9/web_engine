module Web
  class User < ActiveRecord::Base
    include Concerns::HasSiSynchronization

    has_many :promo_codes
    
    def name
      "#{first_name} #{last_name}"
    end

    def shorted_name
      "#{first_name} #{last_name[0]}"
    end

    def rate_average
      feedbacks = Feedback.where(user_id: self.id)
      feedbacks = feedbacks.to_a
      feedbacks = feedbacks.map(&:rating).compact.uniq

      feedbacks.count > 0 ? (feedbacks.inject(:+) / feedbacks.count).to_i : 0
    end

    def display_name
      name
    end

    def age
      now = Time.now.utc.to_date
      now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
    end

    def authorize!
      update(authorized_by_guardian: true)
    end

    def unauthorize!
      update(authorized_by_guardian: false)
    end

    def confirm!
      update(confirmed_at: Time.now)
    end

    def promo_code
      promo_codes.map(&:promo_code).join(', ')
    end 
  end
end
