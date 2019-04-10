require 'csv'

module Stats
  class Audit

    COLUMN_NAMES = %w{
      case_number
      case_type
      trigger
      status
      responding_team
      date_received
      draft_deadline
      final_deadline
      date_responded
      in_time
      info_held
      granted
      exemptions
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
      kase = Case::Base.find(case_id).decorate
      arry << kase.number
      arry << kase.decorate.pretty_type
      arry << kase.flagged? ? 'YES' : 'NO'
      arry << kase.status
      arry << responding_team(kase)
      arry << kase.received_date.strftime('%Y-%m-%d')
      arry << format_date(kase.internal_deadline)
      arry << format_date(kase.external_deadline)
      arry << date_responded(kase)
      arry << in_time(kase)
      arry << kase.info_held_status&.name
      arry << kase.outcome&.name
      arry << kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(',')
    end

    def last_assigned_date(kase)
      assignment_transition = kase.transitions.where(event: 'assign_responder').last
      assignment_transition&.created_at&.to_date
    end

    def format_date(date)
      if date.is_a?(Date)
        date.strftime('%Y-%m-%d')
      elsif date.blank?
        ''
      else
        date.to_date.strftime('%Y-%m-%d')
      end
    end

    def date_responded(kase)
      transition = kase.responded_transitions.last
      if transition
        transition.created_at.strftime('%Y-%m-%d')
      else
        ''
      end
    end

    def in_time(kase)
      if kase.date_responded
        kase.date_responded > kase.external_deadline.to_date ? 'No' : 'Yes'
      else
        ''
      end
    end

    def responding_team(kase)
      if kase.assignments.responding.any?
        kase.assignments.responding.last.team.name
      else
        ''
      end
    end

  end
end
