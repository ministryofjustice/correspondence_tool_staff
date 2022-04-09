module Stats
  # rubocop:disable Metrics/ClassLength
  class R004CabinetOfficeReport < BaseReport

    COLUMNS = {
      desc:   "Description",
      value:  "Value"
    }

    # The Cabinet Office report is one of the few to remain purely
    # in CSV format
    class << self
      def report_format
        BaseReport::CSV
      end
    end

    def initialize(**options)
      super
      @stats = StatsCollector.new(report_lines.keys, COLUMNS)
      @first_column_heading = self.class.title
      @superheadings = superheadings
      @report_lines = report_lines

      @scope = Case::Base.standard_foi
    end

    def self.title
      'Cabinet office report'
    end

    def self.description
      'Includes performance data about how we are meeting statutory deadlines and how we are using exemptions.'
    end

    def run(*)
      @report_lines.keys.each do |category|
        next if category =~ /^_/
        populate_category(category)
      end
      self
    end

    def report_type
      ReportType.r004
    end

    private

    # rubocop:disable Metrics/MethodLength
    def report_lines
      {
        '_FOI CASES'  => '',
        '_TIMELINESS' => "",
        '_THE CASES UNDER SECTION 4 ARE EXCLUDED' => "",
        '1.A'         => "Total number of FOI requests received this period",
        '1.Ai'        => "Of these, number which fall fully or mostly under the Environmental Information Regulations (EIRs)",
        '1.B'         => "Number of requests that have been created but not closed in this period",
        '1.Bi'        => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Bii'       => "Number of requests still outstanding where a fee has been charged or a fee notice issued, including those where where the payment deadline has elapsed and the request has not been processed",
        '1.Biii'      => "Number of requests created this period, that are yet to be closed, that have gone over the 20 day deadline",
        '1.C'         => "Number of requests that have been created and closed within this period",
        '1.Ci'        => "Number of requests created and processed in this period that were within time against the external deadline",
        '1.Cii'       => "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation",
        '1.Ciii'      => "Number of requests that have been created and closed within this period that were out of time against the external deadline",
        '_SPACER_1'   => "",
        '_OUTCOMES'   => "",
        '_THE CASES UNDER SECTION 4 ARE EXCLUDED ' => "",
        '2.A'         => "Number of requests that have been created and closed within this period (Replicates 'C' above in TIMELINESS section)",
        '2.B'         => "Number of cases created and closed in this period that have been marked as 'Granted in full'",
        '2.C'         => "Number of cases created and closed in this period that have been marked as 'Clarification required - S1(3)'",
        '2.D'         => "Number of cases created and closed in this period that have been marked as 'Refused fully' and with a 'reason for refusal' of 'Information not held'",
        '2.E'         => "Number of cases created and closed in this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(1)) - vexatious'",
        '2.F'         => "Number of cases created and closed in this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'",
        '2.G'         => "Number of cases created and closed in this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'",
        '2.H'         => "Number of cases created and closed in this period that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'",
        '2.I'         => "Number of cases created and closed in this period that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'",
        '_SPACER_2'   => '',
        '_USE OF EXEMPTIONS AND EXCEPTIONS' => '',
        '_SPACER_7'   => '',
        '3.A'         => "Number of cases created and closed in this period that were fully or partly refused. = 2.H + 2.I",
        '_USE OF THE FOLLOWING EXEMPTIONS LISTED AT PART II OF THE FOI ACT' => '',
        '_Number of cases created and closed in this period that have been marked as refused fully or refused in part with the exemption of ' => '', 
        '3.S22'       => "S(22) - Information intended for future publication",
        '3.S22A'      => "S(22A) - Research intended for future publication.",
        '3.S23'       => "S(23) - Information supplied by, or relating to, bodies dealing with security matters",
        '3.S24'       => "S(24) - National security",
        '3.S26'       => "S(26) - Defence'",
        '3.S27'       => "S(27) - International relations",
        '3.S28'       => "S(28) - Relations within the United Kingdom",
        '3.S29'       => "S(29) - The economy",
        '3.S30'       => "S(30) - Investigations and proceedings conducted by public authorities",
        '3.S31'       => "S(31) - Law enforcement",
        '3.S32'       => "S(32) - Court records, etc",
        '3.S33'       => "S(33) - Audit functions",
        '3.S34'       => "S(34) - Parliamentary privilege",
        '3.S35'       => "S(35) - Formulation of government policy, etc",
        '3.S36'       => "S(36) - Prejudice to effective conduct of public affairs",
        '3.S37'       => "S(37) - Communications with Her Majesty, etc. and honours",
        '3.S38'       => "S(38) - Health and safety",
        '3.S40'       => "S(40) - Personal information",
        '3.S41'       => "S(41) - Information provided in confidence",
        '3.S42'       => "S(42) - Legal professional privilege",
        '3.S43'       => "S(43) - Commercial interests",
        '3.S44'       => "S(44) - Prohibitions on disclosure",
        '_SPACER_8'   => '',
        '_USE OF SECTION 21 EXEMPTIONS' => '',
        '4.A'         => "Number of requests created and closed this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of" +
                            "'Exemption applied' and 'What exemption applied' selection of '(s21) - Information accessible by other means' and this was the ONLY exemption marked for this case",
        '4.B'         => "Number of requests created and closed this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of " +
                              "'Exemption applied' and 'What exemption applied' selection of '(s21) - Information accessible by other means' and this was the " +
                              "ONLY exemption marked for this case and the case was processed IN TIME against the external deadline",
        '4.C'         => "Number of requests created and closed this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of" +
                              "'Exemption applied' and 'What exemption applied' selection of '(s21) - Information accessible by other means' and this was the " +
                              "ONLY exemption marked for this case and the case was processed OUT OF TIME against the external deadline",
        '_SPACER_3'   => '',
        '_ICO APPEAL CASES'  => '',
        '_SPACER_4'   => '',
        '_INFORMATION HELD' => '',
        '5.Ai'        => "Number of cases created in this period that have been marked as 'Information not held'",
        '_SPACER_5'   => '',
        '_REFUSAL REASON' => '',
        '_USE OF SECTION 12/14 EXEMPTIONS' => '',
        '6.S12'       => "Number of cases created in this period that have been with a 'reason for refusal' of " +
                            "'S(12(12)) - Exceeded cost to investigate' or '(s12(1)) - Exceeded cost to obtain'",
        '6.S14'       => "Number of cases created in this period that have been with a 'reason for refusal' of " +
                            "'S(14(1)) - Vexatious' or 'S(14(2)) - Repeated request' ",
        '_SPACER_6'   => '',
        '_USE OF THE FOLLOWING EXEMPTIONS LISTED AT PART II OF THE FOI ACT FROM ORIGINAL CASE' => '',
        '_Number of cases created and closed in this period that have been marked as refused fully or refused in part with the exemption of  ' => '', 
        '7.S21'   => "S(21) - Information accessible by other means",
        '7.S22'   => "S(22) - Information intended for future publication",
        '7.S22A'  => "S(22A) - Research intended for future publication.",
        '7.S23'   => "S(23) - Information supplied by, or relating to, bodies dealing with security matters",
        '7.S24'   => "S(24) - National security",
        '7.S26'   => "S(26) - Defence",
        '7.S27'   => "S(27) - International relations",
        '7.S28'   => "S(28) - Relations within the United Kingdom",
        '7.S29'   => "S(29) - The economy",
        '7.S30'   => "S(30) - Investigations and proceedings conducted by public authorities",
        '7.S31'   => "S(31) - Law enforcement",
        '7.S32'   => "S(32) - Court records, etc",
        '7.S33'   => "S(33) - Audit functions",
        '7.S34'   => "S(34) - Parliamentary privilege",
        '7.S35'   => "S(35) - Formulation of government policy, etc",
        '7.S36'   => "S(36) - Prejudice to effective conduct of public affairs",
        '7.S37'   => "S(37) - Communications with Her Majesty, etc. and honours",
        '7.S38'   => "S(38) - Health and safety",
        '7.S40'   => "S(40) - Personal information",
        '7.S41'   => "S(41) - Information provided in confidence",
        '7.S42'   => "S(42) - Legal professional privilege",
        '7.S43'   => "S(43) - Commercial interests",
        '7.S44'   => "S(44) - Prohibitions on disclosure",
      }
    end
    # rubocop:enable Metrics/MethodLength

    # use method missing to get values for 3_S22 - to 3_S44
    def method_missing(method_name, *args)
      if method_name.to_s =~ /^get_value_3_S(.*)/
        exemption_number = "s#{$1}"
        fully_and_part_refused_with_exemption(exemption_number.downcase)
      elsif method_name.to_s =~ /^get_value_7_S(.*)/
        exemption_number = "s#{$1}"
        fully_and_part_refused_with_exemption_ico(exemption_number.downcase)
      else
        super
      end
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

    def cases_with_only_one_exemption
      @scope
        .joins(:exemptions)
        .select('cases.id')
        .group('cases.id')
        .having("count(cases_exemptions.id) = ?", 1)
    end 

    def scope_with_exemption_s21_only(scope)
      exemption = CaseClosure::Exemption.__send__('s21')
      scope
        .where(id: cases_with_only_one_exemption)
        .joins(:exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end

    def scope_with_pit_extension(scope)
      scope.where("properties->>'has_pit_extension'::text = ?", true.to_s)
    end

    def get_value_1_A
      cases_received_in_period.count - scope_with_exemption_s21_only(cases_received_in_period).count
    end

    def get_value_1_Ai
      'N/A'
    end

    def get_value_1_B
      open_cases_received_in_period.count
    end

    def get_value_1_Bi
      scope_with_pit_extension(open_cases_received_in_period).count
    end

    def get_value_1_Bii
      0
    end

    def get_value_1_Biii
      open_late_cases_received_in_period.count - scope_with_pit_extension(open_late_cases_received_in_period).count
    end

    def open_late_cases_received_in_period
      open_cases_received_in_period.where("properties->>'external_deadline' < ?", Time.zone.today)
    end

    def get_value_1_C
      closed_cases_received_in_period.count - scope_with_exemption_s21_only(closed_cases_received_in_period).count
    end

    def get_value_1_Ci
      (cases_received_and_closed_in_period_responded_in_time.count - scope_with_exemption_s21_only(cases_received_and_closed_in_period_responded_in_time).count) - 
      (responded_in_time_with_pit_extension.count - scope_with_exemption_s21_only(responded_in_time_with_pit_extension).count)
    end

    def get_value_1_Cii
      responded_in_time_with_pit_extension.count + responded_late_with_pit_extension.count -
      scope_with_exemption_s21_only(responded_in_time_with_pit_extension).count -
      scope_with_exemption_s21_only(responded_late_with_pit_extension).count
    end

    def responded_in_time_with_pit_extension
      scope_with_pit_extension(cases_received_and_closed_in_period_responded_in_time)
    end

    def responded_late_with_pit_extension
      scope_with_pit_extension(cases_received_and_closed_in_period_responded_late)
    end

    def get_value_1_Ciii
      (cases_received_and_closed_in_period_responded_late.count - scope_with_exemption_s21_only(cases_received_and_closed_in_period_responded_late).count ) - 
      (responded_late_with_pit_extension.count - scope_with_exemption_s21_only(responded_late_with_pit_extension).count)
    end

    def get_value_2_A
      get_value_1_C
    end

    def get_value_2_B
      granted = CaseClosure::Outcome.granted
      cases_received_and_closed_in_period.where(outcome_id: granted.id).count
    end

    def get_value_2_C
      rr_clarify = CaseClosure::RefusalReason.tmm
      cases_received_and_closed_in_period.where(refusal_reason_id: rr_clarify.id).count
    end

    def get_value_2_D
      cases_received_and_closed_in_period.where(info_held_status: CaseClosure::InfoHeldStatus.not_held).count
    end

    def get_value_2_E
      reason = CaseClosure::RefusalReason.vex
      info_not_confirmed_cases_received_and_closed_in_period.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_F
      reason = CaseClosure::RefusalReason.repeat
      info_not_confirmed_cases_received_and_closed_in_period.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_G
      # this stat needs to count:
      # * Exemption s12(1) when info held in full and part or fully refused
      # * Refusal reason s12(2) when info held = Other
      num_s12_fully_refused_with_exemptions + num_s12_part_refused_with_exemptions + num_s12_refusal_reasons
    end

    def num_s12_fully_refused_with_exemptions
      exemption = CaseClosure::Exemption.s12
      fully_refused_cases_received_and_closed_in_period_with_exemption(exemption).count
    end

    def num_s12_part_refused_with_exemptions
      exemption = CaseClosure::Exemption.s12
      part_refused_cases_received_and_closed_in_period_with_exemption(exemption).count
    end

    def num_s12_refusal_reasons
      reason = CaseClosure::RefusalReason.cost
      info_not_confirmed_cases_received_and_closed_in_period.where(refusal_reason_id: reason.id).count
    end

    def get_value_2_H
      # part refused_cases with an exemption - just count number of part refused cases, because each
      # part refused case must have at least on exemption
      part_refused_cases_closed_in_period.count - num_s12_part_refused_with_exemptions - 
      scope_with_exemption_s21_only(part_refused_cases_closed_in_period).count
    end

    def get_value_2_I
      # fully refused_cases with an exemption - just count number of fully refused cases, because each
      # fully refused case must have at least on exemption
      fully_refused_cases_received_and_closed_in_period.count - num_s12_fully_refused_with_exemptions -
      scope_with_exemption_s21_only(fully_refused_cases_received_and_closed_in_period).count
    end

    def get_value_3_A
      @stats.stats['2.H'][:value] + @stats.stats['2.I'][:value]
    end

    def get_value_4_A
      fully_and_part_refused_cases_recevied_and_closed_in_period_with_exemption_s21.count
    end

    def get_value_4_B
      fully_and_part_refused_cases_recevied_and_closed_in_period_with_exemption_s21.in_time.count
    end

    def get_value_4_C
      fully_and_part_refused_cases_recevied_and_closed_in_period_with_exemption_s21.late.count
    end

    def get_value_5_Ai
      ifo_held_status = CaseClosure::InfoHeldStatus.not_held
      cases_received_in_period_ico.where(info_held_status_id: ifo_held_status.id).count
    end

    def get_value_6_S12
      num_s12_exemptions_ico + num_s12_refusal_reasons_ico
    end

    def num_s12_exemptions_ico
      exemption = CaseClosure::Exemption.s12
      fully_and_part_refused_cases_received_in_period_with_exemption_ico(exemption).count
    end 

    def num_s12_refusal_reasons_ico
      refusal_reason = CaseClosure::RefusalReason.cost
      cases_received_in_period_ico.where(refusal_reason_id: refusal_reason.id).count
    end

    def get_value_6_S14
      num_s14_1_refusal_reason + num_s14_2_refusal_reason
    end

    def num_s14_1_refusal_reason
      refusal_reason = CaseClosure::RefusalReason.vex
      cases_received_in_period_ico.where(refusal_reason_id: refusal_reason.id).count
    end

    def num_s14_2_refusal_reason
      refusal_reason = CaseClosure::RefusalReason.repeat
      cases_received_in_period_ico.where(refusal_reason_id: refusal_reason.id).count
    end

    def get_value_3_S21
      exemption = CaseClosure::Exemption.__send__('s21')
      fully_refused_cases_received_in_period_with_exemption_ico(exemption).count
    end

    def cases_received_and_closed_in_period_responded_late
      cases_received_and_closed_in_period.where("(properties->>'external_deadline')::date < date_responded")
    end

    def cases_received_and_closed_in_period_responded_in_time
      cases_received_and_closed_in_period.where("(properties->>'external_deadline')::date >= date_responded")
    end

    def fully_and_part_refused_cases_recevied_and_closed_in_period_with_exemption_s21
      exemption = CaseClosure::Exemption.__send__('s21')
      fully_and_part_refused_cases_received_and_closed_in_period_with_exemption(exemption)
        .where(id: cases_with_only_one_exemption)
    end

    def fully_and_part_refused_with_exemption(exemption_number)
      exemption = CaseClosure::Exemption.__send__(exemption_number)
      fully_and_part_refused_cases_received_and_closed_in_period_with_exemption(exemption).count
    end

    def cases_received_in_period
      @scope.where(received_date: [@period_start..@period_end])
    end

    def open_cases_received_in_period
      @scope.opened.where(received_date: [@period_start..@period_end])
    end

    def closed_cases_received_in_period
      @scope.closed.where(received_date: [@period_start..@period_end])
    end

    def cases_received_and_closed_in_period
      @scope.closed.where(received_date: [@period_start..@period_end])
    end

    def fully_refused_cases_received_and_closed_in_period
      outcome = CaseClosure::Outcome.fully_refused
      ncnd = CaseClosure::RefusalReason.ncnd
      cases_received_and_closed_in_period
        .where(outcome_id: outcome.id)
        .or(cases_received_and_closed_in_period
          .where(refusal_reason_id: ncnd.id))
    end

    def part_refused_cases_received_and_closed_in_period
      outcome = CaseClosure::Outcome.part_refused
      cases_received_and_closed_in_period.where(outcome_id: outcome.id)
    end

    def fully_or_part_refused_cases_received_and_closed_in_period
      fully_refused = CaseClosure::Outcome.fully_refused
      part_refused = CaseClosure::Outcome.part_refused
      ncnd = CaseClosure::RefusalReason.ncnd
      cases_received_and_closed_in_period
        .where(outcome_id: [fully_refused.id, part_refused.id])
        .or(cases_received_and_closed_in_period
          .where(refusal_reason_id: ncnd.id))
    end

    def part_refused_cases_closed_in_period
      part_refused = CaseClosure::Outcome.part_refused
      cases_received_and_closed_in_period.where(outcome_id: part_refused.id)
    end

    def fully_refused_cases_received_and_closed_in_period_with_exemption(exemption)
      fully_refused_cases_received_and_closed_in_period.left_outer_joins(:exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end

    def part_refused_cases_received_and_closed_in_period_with_exemption(exemption)
      part_refused_cases_received_and_closed_in_period.left_outer_joins(:exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end

    def fully_and_part_refused_cases_received_and_closed_in_period_with_exemption(exemption)
      fully_or_part_refused_cases_received_and_closed_in_period.left_outer_joins(:exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end

    def info_not_confirmed_cases_received_and_closed_in_period
      info_not_confirmed = CaseClosure::InfoHeldStatus.not_confirmed
      cases_received_and_closed_in_period.where(info_held_status_id: info_not_confirmed.id)
    end

    def cases_received_in_period_ico
      cases_original_foi_with_linked_ico_appeal.where("ico_appeal_foi": {"received_date": [@period_start..@period_end]})
    end

    def cases_received_in_period_and_closed_ico
      cases_received_in_period_ico.closed
    end

    def cases_from_ico_appeal_cases_received_in_period_and_open
      cases_received_in_period_ico.opened
    end

    def cases_original_foi_with_linked_ico_appeal
      Case::FOI::Standard.joins("join linked_cases on cases.id=linked_cases.linked_case_id")
            .where("linked_cases": {type: 'original' })
            .joins("join cases as ico_appeal_foi on ico_appeal_foi.id = linked_cases.case_id")
            .where("ico_appeal_foi": {type: 'Case::ICO::FOI', 
                                      "deleted": false})
    end

    def fully_and_part_refused_with_exemption_ico(exemption_number)
      exemption = CaseClosure::Exemption.__send__(exemption_number)
      fully_and_part_refused_cases_received_in_period_with_exemption_ico(exemption).count
    end

    def fully_and_part_refused_cases_received_in_period_with_exemption_ico(exemption)
      fully_and_part_refused_cases_received_in_period_ico.left_outer_joins(:exemptions).where('cases_exemptions.exemption_id = ?', exemption.id)
    end

    def fully_and_part_refused_cases_received_in_period_ico
      fully_refused = CaseClosure::Outcome.fully_refused
      part_refused = CaseClosure::Outcome.part_refused
      ncnd = CaseClosure::RefusalReason.ncnd
      cases_received_in_period_ico
        .where(outcome_id: [fully_refused.id, part_refused.id])
        .or(cases_received_in_period_ico
          .where(refusal_reason_id: ncnd.id))
    end

    def superheadings
      [
        ["Dated: #{Time.zone.today.strftime(Settings.default_date_format)}"],
        ["For period #{@period_start.strftime(Settings.default_date_format)} to #{@period_end.strftime(Settings.default_date_format)}"]
      ]
    end

  end
end
# rubocop:enable Metrics/ClassLength
