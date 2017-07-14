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
        '_TIMELINESS' => "",
        '1.A'         => "Total number of FOI requests received this quarter",
        '1.Ai'        => "Of these, number which fall fully or mostly under the Environmental Information Regulations (EIRs)",
        '1.B'         => "Number of requests that have been created but not closed in this quarter",
        '1.Bi'        => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Bii'       => "Number of requests still outstanding where a fee has been charged or a fee notice issued, including those where where the payment deadline has elapsed and the request has not been processed",
        '1.Biii'      => "Number of requests created this quarter, that are yet to be closed, that have gone over the 20 day deadline",
        '1.C'         => "Number of requests that have been created and closed within this quarter",
        '1.Ci'        => "Number of requests created and processed in this quarter that were within time against the external deadline",
        '1.Cii'       => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Ciii'      => "Number of requests that have been created and closed within this quarter that were out of time against the external deadline",
        '_SPACER_1'   => "",
        '_OUTCOMES'   => "",
        '2.A'         => "Number of requests that have been created and closed within this quarter (Replicates 'C' above in TIMELINESS section)",
        '2.B'         => "Number of cases created and closed in this quarter that have been marked as 'Granted in full'",
        '2.C'         => "Number of cases created and closed in this quarter that have been marked as 'Clarification required - S1(3)'",
        '2.D'         => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' and with a 'reason for refusal' of 'Information not held'",
        '2.E'         => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(1)) - vexatious'",
        '2.F'         => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'",
        '2.G'         => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'",
        '2.H'         => "Number of cases created and closed in this quarter that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'",
        '2.I'         => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'",
        '_SPACER_2'   => '',
        '_USE OF EXEMPTIONS AND EXCEPTIONS' => '',
        '3.A'         => "Number of cases created and closed in this quarter that were fully or partly refused",
        '3.S22'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(22) - Information intended for future publication'",
        '3.S22A'      => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of S(22) - 'S(22A) - Research intended for future publication.'",
        '3.S23'       =>  "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(23) - Information supplied by, or relating to, bodies dealing with security matters",
        '3.S24'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(24) - National security'",
        '3.S26'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(26) - Defence'",
        '3.S27'       =>  "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of "+
                            "'Exemption applied' and 'What exemption applied' selection of 'S(27) - International relations'",
        '3.S28'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(28) - Relations within the United Kingdom'",
        '3.S29'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(29) - The economy'",
        '3.S30'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(30) - Investigations and proceedings conducted by public authorities",
        '3.S31'       => "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(31) - Law enforcement'",
        '3.S32'       => " Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of " +
                            "'Exemption applied' and 'What exemption applied' selection of 'S(32) - Court records, etc'"

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
      fully_refused_cases_received_and_closed_this_quarter.where(refusal_reason_id: reason.id).count
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
      fully_refused_cases_received_and_closed_this_quarter.where(refusal_reason_id: reason.id).count
    end

    def get_value_3_A
      @stats.stats['2.H'][:value] + @stats.stats['2.I'][:value]
    end


    # use method missing to get values for 3_S22 - to 3_S44
    def method_missing(method_name)
      if method_name.to_s =~ /^get_value_3_S(.*)/
        exemption_number = "s#{$1}"
        fully_refused_with_exemption(exemption_number.downcase)
      else
        super
      end
    end

    def fully_refused_with_exemption(exemption_number)
      exemption = CaseClosure::Exemption.__send__(exemption_number)
      fully_refused_cases_received_and_closed_this_quarter_with_exemption(exemption).count
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

    def fully_refused_cases_received_and_closed_this_quarter
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

    def fully_refused_cases_received_and_closed_this_quarter_with_exemption(exemption)
      fully_refused_cases_received_and_closed_this_quarter.joins(:cases_exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end


    def superheadings
      [
        ["Dated: #{Date.today.strftime(Settings.default_date_format)}"],
      ]
    end

  end
end
