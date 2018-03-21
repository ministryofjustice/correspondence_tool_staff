require 'csv'

module Stats
  class R006FullDataExport

    COLUMN_NAMES = %W{
      case_number
      case_type
      date_created
      date_received
      draft_deadline
      final_deadline
      date_responded
      current_state
      business_unit
      information_officer
      deputy_director
      delivery_method
      disclosure_clearance
      press_office_clearance
      private_office_clearance
      name
      requester_type
      email
      postal_address
      subject
      message
      info_held
      appeal_outcome
      outcome
      refusal_reason
      exemptions
    }

    def initialize
      @filename = "#{ENV["HOME"]}/full_data_export.csv"
      @date_format = Settings.default_date_format
    end

    def run
      case_ids = Case.pluck(:id)
      CSV.open(@filename, 'wb') do |csv|
        csv << COLUMN_NAMES
        case_ids.each do |case_id|
          csv << values_for_case(case_id)
        end
      end
    end

    private

    def values_for_case(case_id)
      kase = Case.find(case_id).decorate
      row = []
      row << kase.number
      row << kase.pretty_type
      row << kase.created_at.strftime(@date_format)
      row << kase.received_date.strftime(@date_format)
      row << kase.object.internal_deadline.strftime(@date_format)
      row << kase.object.external_deadline.strftime(@date_format)
      row << kase.object.date_responded&.strftime(@date_format)
      row << kase.current_state
      row << kase.responding_team&.name
      row << kase.responder&.full_name
      row << kase.responding_team&.team_lead
      row << kase.delivery_method
      row << kase.flagged_for_disclosure_specialist_clearance? ? 'TRUE' : 'FALSE'
      row << kase.flagged_for_press_office_clearance? ? 'TRUE' : 'FALSE'
      row << kase.flagged_for_private_office_clearance? ? 'TRUE' : 'FALSE'
      row << kase.name
      row << kase.requester_type
      row << kase.email
      row << kase.postal_address
      row << kase.subject
      row << kase.message
      row << kase.info_held_status&.name
      row << kase.appeal_outcome&.name
      row << kase.refusal_reason&.name
      row << kase.exemptions.map(&:name).join("\n")
    end
  end
end
