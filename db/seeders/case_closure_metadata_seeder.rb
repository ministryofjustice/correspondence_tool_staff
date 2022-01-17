module CaseClosure
  #rubocop:disable Metrics/ClassLength
  class MetadataSeeder

    def self.seed!(verbose: false)
      seed_outcomes(verbose)
      seed_appeal_outcomes(verbose)
      seed_refusal_reasons(verbose)
      seed_exemptions(verbose)
      seed_outcome_reasons(verbose)
      implement_oct_2017_changes(verbose)
      implement_jan_2021_changes(verbose)
      implement_feb_2021_changes(verbose)
    end

    def self.unseed!
      CaseClosure::Metadatum.delete_all
    end

    def self.seed_outcomes(verbose)
      puts "----Seeding CaseClosure::Outcomes----" if verbose
      Outcome.find_or_create_by!(subtype: nil, name: 'Granted in full', abbreviation: 'granted', sequence_id: 10)
      rec1 = Outcome.find_or_create_by!(subtype: nil, name: 'Refused in part', abbreviation: 'part', sequence_id: 20)
      rec2 = Outcome.find_or_create_by!(subtype: nil, name: 'Refused fully', abbreviation: 'refused', sequence_id: 30)
      rec3 = Outcome.find_or_create_by!(subtype: nil, name: 'Clarification needed - Section 1(3)', abbreviation: 'clarify', sequence_id: 15)
      rec3.update!(active: false)

      [rec1, rec2].each { |r| r.update_attribute(:requires_refusal_reason, true) }
    end

    def self.seed_appeal_outcomes(verbose)
      puts "----Seeding CaseClosure::AppealOutcomes----" if verbose
      AppealOutcome.find_or_create_by!(subtype: nil, name: 'Upheld', abbreviation: 'upheld', sequence_id: 40)
      AppealOutcome.find_or_create_by!(subtype: nil, name: 'Upheld in part', abbreviation: 'part_upheld', sequence_id: 50)
      AppealOutcome.find_or_create_by!(subtype: nil, name: 'Overturned', abbreviation: 'overturned', sequence_id: 60)
    end

    #rubocop:disable Metrics/MethodLength
    def self.seed_refusal_reasons(verbose)
      puts "----Seeding CaseClosure::RefusalReasons----" if verbose

      exemption = RefusalReason.find_or_create_by!(
        subtype: nil,
        name: 'Exemption applied',
        abbreviation: 'exempt',
        sequence_id: 110,
        active: false)

      exemption.update_attribute(:requires_exemption, true)

      RefusalReason.find_or_create_by!(
        subtype: nil,
        name: 'Information not held',
        abbreviation: 'noinfo',
        sequence_id: 120,
        active: false)

      RefusalReason.find_or_create_by!(
        subtype: nil,
        name: 's8(1) - Conditions for submitting request not met',
        abbreviation: 'notmet',
        sequence_id: 130)

      # Old refusal reason, replaced by the one below.
      #
      # Necessary to run 'db:setup' because it looks like these refusal reasons
      # are already created at that point, and we get the error:
      #
      #   ActiveRecord::RecordInvalid: Validation failed: Abbreviation has already been taken
      #
      # RefusalReason.find_or_create_by!(
      #   subtype: nil,
      #   name: '(s12) - Exceeded cost',
      #   abbreviation: 'cost',
      #   sequence_id: 140)

      RefusalReason.find_or_create_by!(
        subtype: nil,
        name: '(s12(2)) - Exceeded cost to investigate',
        abbreviation: 'cost',
        sequence_id: 140)

      RefusalReason.find_or_create_by!(
        subtype: nil,
        name: '(s14(1)) - Vexatious',
        abbreviation: 'vex',
        sequence_id: 150)

      RefusalReason.find_or_create_by!(
        subtype: nil,
        name: '(s14(2)) - Repeated request',
        abbreviation: 'repeat',
        sequence_id: 160)
    end

    def self.seed_exemptions(verbose)
      puts "----Seeding CaseClosure::Exemptions----" if verbose
      Exemption.find_or_create_by!(
        subtype: 'ncnd',
        name: 'Neither confirm nor deny (NCND)',
        abbreviation: 'ncnd',
        sequence_id: 410)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s21) - Information accessible by other means',
        abbreviation: 'othermeans',
        sequence_id: 510)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s23) - Information supplied by, or relating to, bodies dealing with security matters',
        abbreviation: 'security',
        sequence_id: 520)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s32) - Court records',
        abbreviation: 'court',
        sequence_id: 530)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s34) - Parliamentary privilege',
        abbreviation: 'pp',
        sequence_id: 540)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s40) - Personal information',
        abbreviation: 'pers',
        sequence_id: 550)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s41) - Information provided in confidence',
        abbreviation: 'conf',
        sequence_id: 560)

      Exemption.find_or_create_by!(
        subtype: 'absolute',
        name: '(s44) - Prohibitions on disclosure',
        abbreviation: 'prohib',
        sequence_id: 570)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s22) - Information intended for future publication',
        abbreviation: 'future',
        sequence_id: 605)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s22A) - Research intended for future publication',
        abbreviation: 'research',
        sequence_id: 610)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s24) - National security',
        abbreviation: 'natsec',
        sequence_id: 615)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s26) - Defence',
        abbreviation: 'defence',
        sequence_id: 620)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s27) - International relations',
        abbreviation: 'intrel',
        sequence_id: 625)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s28) - Relations within the United Kingdom',
        abbreviation: 'ukrel',
        sequence_id: 630)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s29) - The economy',
        abbreviation: 'economy',
        sequence_id: 635)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s30) - Investigations and proceedings conducted by public authorities',
        abbreviation: 'pubauth',
        sequence_id: 640)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s31) - Law enforcement',
        abbreviation: 'law',
        sequence_id: 645)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s33) - Audit functions',
        abbreviation: 'audit',
        sequence_id: 650)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s35) - Formulation of government policy',
        abbreviation: 'policy',
        sequence_id: 655)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s36) - Prejudice to effective conduct of public affairs',
        abbreviation: 'prej',
        sequence_id: 660)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s37) - Communication with Her Majesty, etc. and honours',
        abbreviation: 'royals',
        sequence_id: 665)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s38) - Health and safety',
        abbreviation: 'elf',
        sequence_id: 670)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s39) - Environment information',
        abbreviation: 'env',
        sequence_id: 675)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s42) - Legal professional privilege',
        abbreviation: 'legpriv',
        sequence_id: 680)

      Exemption.find_or_create_by!(
        subtype: 'qualified',
        name: '(s43) - Commercial interests',
        abbreviation: 'comm',
        sequence_id: 685)
    end

    def self.seed_outcome_reasons(verbose)
      puts "----Seeding CaseClosure::OutcomeReasons----" if verbose

      OutcomeReason.find_or_create_by!(
        name: 'Proper searches not carried out/missing information',
        abbreviation: 'missing_info',
        sequence_id: 900)

      OutcomeReason.find_or_create_by!(
        name: 'Incorrect exemption engaged',
        abbreviation: 'wrong_exemp',
        sequence_id: 905)

      OutcomeReason.find_or_create_by!(
        name: 'Excessive redaction(s)',
        abbreviation: 'excess_redacts',
        sequence_id: 910)
    end
    #rubocop:enable Metrics/MethodLength

    def self.implement_oct_2017_changes(verbose)
      puts 'Updating Case Closure data inline with October 2017 changes' if verbose
      CaseClosure::MetadataSeeder.insert_info_held_status_records
      CaseClosure::MetadataSeeder.add_new_refusal_reasons
      CaseClosure::MetadataSeeder.deactivate_outcome_clarify
      CaseClosure::MetadataSeeder.deactivate_old_refusal_reasons
      CaseClosure::MetadataSeeder.create_new_cost_exemption
      CaseClosure::MetadataSeeder.update_cost_refusal_reason
    end

    def self.insert_info_held_status_records
      InfoHeldStatus.find_or_create_by!(
        subtype: nil,
        name: 'Yes',
        abbreviation: 'held',
        sequence_id: 710
      )

      InfoHeldStatus.find_or_create_by!(
        subtype: nil,
        name: 'No',
        abbreviation: 'not_held',
        sequence_id: 730
      )

      InfoHeldStatus.find_or_create_by!(
        subtype: nil,
        name: 'Held in part',
        abbreviation: 'part_held',
        sequence_id: 720
      )

      InfoHeldStatus.find_or_create_by!(
        subtype: nil,
        name: 'Other',
        abbreviation: 'not_confirmed',
        sequence_id: 740
      )
    end

    def self.add_new_refusal_reasons
      rec = CaseClosure::RefusalReason.find_by_abbreviation('tmm')
      if rec.nil?
        CaseClosure::RefusalReason.create!(
          name: '(s1(3)) - Clarification required',
          abbreviation: 'tmm',
          sequence_id: 100)
      end

      rec = CaseClosure::RefusalReason.find_by_abbreviation('sartmm')
      if rec.nil?
        CaseClosure::RefusalReason.create!(
          name: 'SAR Clarification/Tell Me More',
          abbreviation: 'sartmm',
          sequence_id: 105)
      end

      rec = CaseClosure::RefusalReason.find_by_abbreviation('ncnd')
      if rec.nil?
        CaseClosure::RefusalReason.create!(
          name: 'Neither confirm nor deny (NCND)',
          abbreviation: 'ncnd',
          requires_exemption: true,
          sequence_id: 170)
      end
    end

    def self.deactivate_outcome_clarify
      outcome = CaseClosure::Outcome.find_by_abbreviation!('clarify')
      outcome.update!(active: false)
    end

    def self.deactivate_old_refusal_reasons
      # deactive refusal_reasons 'exempt', 'notmet', and 'noinfo'
      %w{ exempt noinfo notmet }.each do |abbrev|
        rec = CaseClosure::RefusalReason.find_by_abbreviation(abbrev)
        rec.update!(active: false) unless rec.nil?
      end
    end

    def self.create_new_cost_exemption
      CaseClosure::Exemption.find_or_create_by(
        name: '(s12(1)) - Exceeded cost to obtain',
        subtype: 'absolute',
        abbreviation: 'cost',
        omit_for_part_refused: true,
        sequence_id: 505)
    end

    def self.update_cost_refusal_reason
      # update description of refusal reason s12(2)
      cost = CaseClosure::RefusalReason.find_by_abbreviation('cost')
      cost.update!(name: '(s12(2)) - Exceeded cost to investigate') unless cost.nil?
    end

    def self.implement_jan_2021_changes(verbose)
      puts 'Updating Case Closure data inline with January 2021 changes' if verbose
      CaseClosure::MetadataSeeder.insert_appeal_outcome_records_for_offender_sar_complaint
    end

    def self.insert_appeal_outcome_records_for_offender_sar_complaint
      OffenderComplaintAppealOutcome.find_or_create_by!(subtype: nil, name: 'Complaint upheld', abbreviation: 'upheld', sequence_id: 800)
      OffenderComplaintAppealOutcome.find_or_create_by!(subtype: nil, name: 'Complaint not upheld', abbreviation: 'not_upheld', sequence_id: 810)
      OffenderComplaintAppealOutcome.find_or_create_by!(subtype: nil, name: 'No ICO response received', abbreviation: 'not_response_received', sequence_id: 820)
    end

    def self.implement_feb_2021_changes(verbose)
      puts 'Updating Case Closure data inline with February 2021 changes' if verbose
      CaseClosure::MetadataSeeder.insert_outcome_records_for_offender_sar_complaint
      CaseClosure::MetadataSeeder.insert_approval_flags_records_for_offender_sar_complaint
    end

    def self.insert_outcome_records_for_offender_sar_complaint
      OffenderComplaintOutcome.find_or_create_by!(subtype: nil, name: 'Claim was successful', abbreviation: 'succeeded', sequence_id: 900)
      OffenderComplaintOutcome.find_or_create_by!(subtype: nil, name: 'Claim was not successful', abbreviation: 'not_succeeded', sequence_id: 910)
      OffenderComplaintOutcome.find_or_create_by!(subtype: nil, name: 'Claim was settled', abbreviation: 'settled', sequence_id: 920)
    end

    def self.insert_approval_flags_records_for_offender_sar_complaint
      ApprovalFlag::ICOOffenderComplaint.find_or_create_by!(
        subtype: nil, name: 'Has this had Branston operations approval?', abbreviation: 'first_approval', sequence_id: 1000)
      ApprovalFlag::ICOOffenderComplaint.find_or_create_by!(
        subtype: nil, name: 'Has this had deputy director information services approval?', abbreviation: 'second_approval', sequence_id: 1010)
      ApprovalFlag::ICOOffenderComplaint.find_or_create_by!(
        subtype: nil, name: 'No approval needed', abbreviation: 'no_approval_required', sequence_id: 1020)

      ApprovalFlag::LitigationOffenderComplaint.find_or_create_by!(
        subtype: nil, name: 'Has this had fee approval?', abbreviation: 'fee_approval', sequence_id: 1300)
      
    end

  end
  #rubocop:enable Metrics/ClassLength
end
