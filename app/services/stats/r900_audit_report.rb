require "csv"

module Stats
  class R900AuditReport
    attr_reader :report_data

    COLUMN_HEADINGS = %w[
      id
      number
      type
      trigger
      current_state
      bu_id
      business_group
      directorate
      business_unit
      created
      received
      responded
      internal_deadline
      external_deadline
      responded
      outcome
      info_held
      refusal_reason
      appeal_outcome
      deleted
    ].freeze

    # NOTE: Does not run parent constructor
    def initialize(**)
      @case_ids = Case::Base.unscoped.pluck(:id)
      @date_mask = "%Y-%m-%d"
    end

    def run(*)
      @report_data = generate_csv
    end

  private

    def generate_csv
      CSV.generate(headers: true) do |csv|
        csv << COLUMN_HEADINGS
        @case_ids.each do |case_id|
          csv << generate_line(case_id)
        end
      end
    end

    def generate_line(case_id)
      line = []
      kase = Case::Base.unscoped.find(case_id)
      COLUMN_HEADINGS.each do |col|
        meth = col.to_sym

        line << if meth.in?(%i[id number type current_state internal_deadline external_deadline])
                  kase.__send__(meth)
                else
                  __send__(meth, kase)
                end
      end
      line
    end

    def bu_id(kase)
      if kase.responding_team.nil?
        ""
      else
        kase.responding_team.id
      end
    end

    def business_group(kase)
      if kase.responding_team.nil?
        ""
      else
        kase.responding_team.business_group.name
      end
    end

    def directorate(kase)
      if kase.responding_team.nil?
        ""
      else
        kase.responding_team.directorate.name
      end
    end

    def business_unit(kase)
      if kkase.responding_team.nil?
        ""
      else
        kase.responding_team.name
      end
    end

    def created(kase)
      kase.created_at.strftime(@date_mask)
    end

    def received(kase)
      kase.received_date.strftime(@date_mask)
    end

    def responded(kase)
      kase.date_responded.nil? ? "" : kase.date_responded.strftime(@date_mask)
    end

    def trigger(kase)
      kase.flagged? ? "Y" : "N"
    end

    def outcome(kase)
      kase.outcome_id.nil? ? "" : kase.outcome.name
    end

    def info_held(kase)
      kase.info_held_status_id.nil? ? "" : kase.info_held_status.name
    end

    def refusal_reason(kase)
      kase.refusal_reason_id.nil? ? "" : kase.refusal_reason.name
    end

    def appeal_outcome(kase)
      kase.appeal_outcome_id.nil? ? "" : kase.appeal_outcome.name
    end

    def deleted(kase)
      kase.deleted ? "Yes" : "No"
    end
  end
end
