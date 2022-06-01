module RetentionSchedules
  class CaseNotClosedError < StandardError
    def message
      "Case cannoted be destroyed as it is still open"
    end
  end

  class NoRetentionScheduleError < StandardError
    def message
      "Cases without Retention Schedules cannot be destroyed"
    end
  end

  class WrongCaseTypeError< StandardError
    def message
      "Non Offender SAR / Offender SAR Compaint cases cannot be destroyed"
    end
  end

  class UnactionableStateError < StandardError
    def message
      "Case must have a Retention Schedule state of to_be_anonymised to be destroyed"
    end
  end

  class AnonymiseCaseService


    ANON_VALUES = {
      case_reference_number: 'XXXX XXXX',
      date_of_birth: Date.new(01, 01, 0001),
      email: 'anon.email@cms-gdpr.justice.gov.uk',
      message: 'XXXX XXXX',
      name: 'XXXX XXXX',
      postal_address: 'XXXX XXXX',
      previous_case_numbers: 'XXXX XXXX',
      prison_number: 'XXXX XXXX',
      requester_reference: 'XXXX XXXX',
      subject: 'XXXX XXXX',
      subject_address: 'XXXX XXXX',
      subject_aliases: 'XXXX XXXX',
      subject_full_name: 'XXXX XXXX',
      third_party_company_name: 'XXXX XXXX',
      third_party_name: 'XXXX XXXX',

      # Offender SAR Complaint specific fields
      gld_contact_email: 'anon.email@cms-gdpr.justice.gov.uk',
      gld_contact_name: 'XXXX XXXX',
      gld_contact_phone: 'XXXX XXXX',
      gld_reference: 'XXXX XXXX',
      ico_contact_email: 'anon.email@cms-gdpr.justice.gov.uk',
      ico_contact_name: 'XXXX XXXX',
      ico_contact_phone: 'XXXX XXXX',
      ico_reference: 'XXXX XXXX',
    }

    ANON_NOTE_MESSAGE_VALUE = 'XXXX XXXX'

    ANON_DATA_REQUEST_NOTE_VALUE = 'XXXX XXXX'

    def initialize(kase:)
      # whole case and links will need to be loaded
      # including trasitions, and data_requests
      @kase = kase
    end


    def call
      guard_clause_checks

      PaperTrail.request(enabled: false) do
      # guard_clauses that throw errors
        ActiveRecord::Base.transaction do
          # for each datapoint on case
          anonymise_core_case_fields
          anonymise_case_notes
          anonymise_cases_data_requests_notes
          update_cases_retention_schedule_state

          # this should always be called last
          destroy_case_versions

          @kase.save
        end
      end 
    end

    private

    def anonymise_core_case_fields
      ANON_VALUES.each do |key, value|
        if @kase.respond_to?(key)
          @kase.update_attribute(key, value)
        end
      end
    end

    def anonymise_case_notes
      notes = @kase.transitions.where(event: 'add_note_to_case')

      if notes
        notes.each do |note|
          note.message = ANON_NOTE_MESSAGE_VALUE
          note.save
        end
      end
    end

    def anonymise_cases_data_requests_notes
      data_requests = @kase.data_requests

      if data_requests
        data_requests.each do |data_request|
          data_request.request_type_note = ANON_DATA_REQUEST_NOTE_VALUE
          data_request.save
        end
      end
    end

    def update_cases_retention_schedule_state
      retention_schedule = @kase.retention_schedule
      retention_schedule.anonymise!
      retention_schedule.erasure_date = Date.today
      retention_schedule.save
    end

    def destroy_case_versions
      @kase.versions.destroy_all
    end

    def guard_clause_checks
      raise RetentionSchedules::WrongCaseTypeError unless @kase.type_of_offender_sar? 
      raise RetentionSchedules::CaseNotClosedError unless @kase.closed?
      raise RetentionSchedules::NoRetentionScheduleError unless @kase.retention_schedule.present?
      raise RetentionSchedules::UnactionableStateError unless @kase.retention_schedule.to_be_anonymised?
    end
  end
end
