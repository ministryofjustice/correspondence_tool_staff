module RetentionSchedules
  class AnonymiseCaseService

    ANON_VALUES = {
      case_reference_number: 'XXXX XXXX',
      date_of_birth: Date.new(01, 01, 0001),
      email: 'anon@email.com',
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
      gld_contact_email: 'XXXX XXXX',
      gld_contact_name: 'XXXX XXXX',
      gld_contact_phone: 'XXXX XXXX',
      gld_reference: 'XXXX XXXX',
      ico_contact_email: 'XXXX XXXX',
      ico_contact_name: 'XXXX XXXX',
      ico_contact_phone: 'XXXX XXXX',
      ico_reference: 'XXXX XXXX',
    }

    ANON_NOTE_MESSAGE_VALUE = 'XXXX XXXX'

    def initialize(kase:)
      # whole case and links will need to be loaded
      @kase = kase
    end

    def call
      # guard_clauses that throw errors
      ActiveRecord::Base.transaction do
        # for each datapoint on case

        anonymise_core_case_fields
        anonymise_case_notes

        @kase.save
      end
    end

    def anonymise_core_case_fields
      ANON_VALUES.each do |key, value|
        if @kase.respond_to?(key)
          @kase.update(key => value)
        end
      end
    end

    def anonymise_case_notes
      notes = @kase.transitions.where(event: 'add_note_to_case')

      notes.each do |note|
        note.message = ANON_NOTE_MESSAGE_VALUE
        note.save
      end
    end
  end
end
