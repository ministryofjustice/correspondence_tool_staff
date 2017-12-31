require 'csv'

module Stats
  class Audit

    COLUMN_NAMES = %w{
      case_number
      trigger
      date_received
      date_last_assigned
      date_approved
      result
    }

    attr_reader :filename

    def initialize(period_start, period_end)
      @period_start = period_start
      @period_end = period_end
      @filename = File.join(ENV['HOME'], 'audit.csv')
    end


    def run
      case_ids = Case::Base.where(received_date: @period_start..@period_end).pluck(:id)
      CSV.open(@filename, 'wb') do |csv|
        csv << COLUMN_NAMES
        case_ids.each do |case_id|
          csv << values_for_case(case_id)
        end
      end
    end

    private

    def values_for_case(case_id)
      arry = []
      kase = Case.find case_id
      arry << kase.number
      arry << kase.flagged? ? 'YES' : 'NO'
      arry << kase.received_date.strftime('%Y-%m-%d')
      if kase.flagged?
        arry << last_assigned_date(kase)
        arry << date_approved(kase)
      else
        arry << ''
        arry << ''
      end
      arry << CaseAnalyser.new(kase).result
    end

    def last_assigned_date(kase)
      kase.transitions.where(event: 'assign_responder').last.created_at.to_date
    end

    def date_approved(kase)
      kase.transitions.where(event: 'approve', acting_team_id: default_clearance_team(kase).id).last&.created_at&.to_date
    end

    def default_clearance_team(kase)
      team_code = Settings.__send__("#{kase.category.abbreviation.downcase}_cases").default_clearance_team
      Team.find_by_code team_code
    end
  end
end
