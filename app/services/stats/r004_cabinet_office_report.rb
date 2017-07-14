module Stats
  class R004CabinetOfficeReport < BaseReport

    COLUMNS = {
      desc:   "Description",
      value:  "Value"
    }

    def initialize
      super
      @month_start = Time.now.beginning_of_month
      @quarter_start = Time.now.beginning_of_quarter
      @year_start = Time.now.beginning_of_year
      @today = Time.now
      @stats = StatsCollector.new(report_lines.keys, COLUMNS)
      @first_column_heading = self.class.title
      @superheadings = superheadings
      @report_lines = report_lines
    end

    def self.title
      'Cabinet Office Report'
    end

    def self.description
      'Provides various statistics for submitting to Cabinet Office'
    end

    def run
      @report_lines.keys.each do |category|
        next if category =~ /^_/
        populate_category(category)
      end
      self
    end

    private

    def report_lines
      {
        '_TIMELINESS'  => "",
        '1.A'          => "Total number of FOI requests received this quarter",
        '1.Ai'         => "Of these, number which fall fully or mostly under the Environmental Information Regulations (EIRs)",
        '1.B'          => "Number of requests that have been created but not closed in this quarter",
        '1.Bi'         => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Bii'        => "Number of requests still outstanding where a fee has been charged or a fee notice issued, including those where where the payment deadline has elapsed and the request has not been processed",
        '1.Biii'       => "Number of requests created this quarter, that are yet to be closed, that have gone over the 20 day deadline",
        '1.C'          => "Number of requests that have been created and closed within this quarter",
        '1.Ci'         => "Number of requests created and processed in this quarter that were within time against the external deadline",
        '1.Cii'        => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Ciii'       => "Number of requests that have been created and closed within this quarter that were out of time against the external deadline",
        '_SPACER_1'    => "",
        '_OUTCOMES'    => "",
        '2.A'          => "Number of requests that have been created and closed within this quarter (Replicates 'C' above in TIMELINESS section)",
        '2.B'          => "Number of cases created and closed in this quarter that have been marked as 'Granted in full'",
        '2.C'          => "Number of cases created and closed in this quarter that have been marked as 'Clarification required - S1(3)'",
        '2.D'          => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' and with a 'reason for refusal' of 'Information not held'",
        '2.E'          => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(1)) - vexatious'",
        '2.F'          => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'",
        '2.G'          => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'",
        '2.H'          => "Number of cases created and closed in this quarter that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'",
        '2.I'          => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'"
      }
    end

    def populate_category(category)
      value = __send__("get_value_#{category.sub('.', '_')}")
      description = @report_lines[category]
      @stats.record_text(category, :desc, description)
      if value.is_a?(String)
        @stats.record_text(category, :value, value)
      else
        @stats.record_stats(category, :value, value)
      end
    end

    def get_value_1_A
      cases_received_this_quarter.count

    end

    def get_value_1_Ai
      'N/A'
    end

    def get_value_1_B
      open_cases_received_this_quarter.count
    end

    def get_value_1_Bi
      'N/A'
    end

    def get_value_1_Bii
      0
    end

    def get_value_1_Biii
      open_cases_received_this_quarter.where("properties->>'external_deadline' < ?", Date.today).count
    end

    def get_value_1_C
      Case.closed.where(received_date: [@quarter_start..@today]).count
    end

    def get_value_1_Ci
      cases_received_and_closed_this_quarter.where("(properties->>'external_deadline')::date >= date_responded").count
    end

    def get_value_1_Cii
      'N/A'
    end

    def get_value_1_Ciii
      cases_received_and_closed_this_quarter.where("(properties->>'external_deadline')::date < date_responded").count
    end

    def get_value_2_A
      get_value_1_C
    end

    def get_value_2_B
      granted = CaseClosure::Outcome.granted
      cases_received_and_closed_this_quarter.where(outcome_id: granted.id).count
    end

    def get_value_2_C
      clarify = CaseClosure::Outcome.clarify
      cases_received_and_closed_this_quarter.where(outcome_id: clarify.id).count
    end

    def get_value_2_D
      reason = CaseClosure::RefusalReason.noinfo
      refused_cases_received_and_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_E
      reason = CaseClosure::RefusalReason.vex
      fully_or_part_refused_cases_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_F
      reason = CaseClosure::RefusalReason.repeat
      fully_or_part_refused_cases_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_G
      reason = CaseClosure::RefusalReason.cost
      fully_or_part_refused_cases_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_H
      reason = CaseClosure::RefusalReason.exempt
      part_refused_cases_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_I
      reason = CaseClosure::RefusalReason.exempt
      refused_cases_received_and_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def cases_received_this_quarter
      Case.where(received_date: [@quarter_start..@today])
    end

    def open_cases_received_this_quarter
      Case.opened.where(received_date: [@quarter_start..@today])
    end

    def cases_received_and_closed_this_quarter
      Case.closed.where(received_date: [@quarter_start..@today])
    end

    def refused_cases_received_and_closed_this_quarter
      outcome = CaseClosure::Outcome.fully_refused
      cases_received_and_closed_this_quarter.where(outcome_id: outcome.id)
    end

    def fully_or_part_refused_cases_closed_this_quarter
      fully_refused = CaseClosure::Outcome.fully_refused
      part_refused = CaseClosure::Outcome.part_refused
      cases_received_and_closed_this_quarter.where(outcome_id: [fully_refused.id, part_refused.id])
    end

    def part_refused_cases_closed_this_quarter
      part_refused = CaseClosure::Outcome.part_refused
      cases_received_and_closed_this_quarter.where(outcome_id: part_refused.id)
    end


    def superheadings
      [
        ["Dated: #{Date.today.strftime(Settings.default_date_format)}"],
      ]
    end

  end
end
