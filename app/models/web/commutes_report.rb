module Web
  class CommutesReport < ActiveRecord::Base
    self.table_name = 'web_commutes_reports'

    def self.initialize_report(title)
      report = CommutesReport.new(report_title: title)
      report.update_attributes(report_key: secure_token)

      report.report_key
    end

    private

    def self.secure_token
      random_token = SecureRandom.urlsafe_base64(nil, false)
      puts random_token

      while CommutesReport.where(report_key: random_token).any? do
        random_token = SecureRandom.urlsafe_base64(nil, false)
      end

      random_token
    end
  end
end