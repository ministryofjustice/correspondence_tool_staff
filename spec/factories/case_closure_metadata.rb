# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#  active                  :boolean          default(TRUE)
#  omit_for_part_refused   :boolean          default(FALSE)
#

FactoryBot.define do
  factory :exemption, class: "CaseClosure::Exemption" do
    requires_refusal_reason { false }
    subtype           { "absolute" }
    name              { "Generic exemption" }
    abbreviation      { "genex" }
    sequence_id       { 404 }

    trait :ncnd do
      subtype           { "ncnd" }
      name              { "Neither confirm nor deny (NCND)" }
      abbreviation      { "ncnd" }
      sequence_id       { 410 }
    end

    trait :absolute do
      subtype           { "absolute" }
      name              { "Generic absolute exemption" }
      abbreviation      { "genabs" }
      sequence_id       { 405 }
    end

    trait :qualified do
      subtype           { "qualified" }
      name              { "Generic qualified exemption" }
      abbreviation      { "genqual" }
      sequence_id       { 601 }
    end

    trait :s12_1 do
      subtype           { "absolute" }
      name              { "(s12(1)) - Exceeded cost to obtain" }
      abbreviation      { "cost" }
      sequence_id       { 505 }
    end

    trait :s21 do
      subtype           { "absolute" }
      name              { "(s21) - Information accessible by other means" }
      abbreviation      { "othermeans" }
      sequence_id       { 510 }
    end

    trait :s12 do
      subtype           { "absolute" }
      name              { "(s12(1))  - Exceeded cost to obtain" }
      abbreviation      { "cost" }
      sequence_id       { 512 }
    end

    trait :s23 do
      subtype           { "absolute" }
      name              { "(s23) - Information supplied by, or relating to, bodies dealing with security matters" }
      abbreviation      { "security" }
      sequence_id       { 520 }
    end

    trait :s32 do
      subtype           { "absolute" }
      name              { "(s32) - Court records" }
      abbreviation      { "court" }
      sequence_id       { 530 }
    end

    trait :s34 do
      subtype           { "absolute" }
      name              { "(s34) - Parliamentary privilege" }
      abbreviation      { "pp" }
      sequence_id       { 540 }
    end

    trait :s40 do
      subtype           { "absolute" }
      name              { "(s40) - Personal information" }
      abbreviation      { "pers" }
      sequence_id       { 550 }
    end

    trait :s41 do
      subtype           { "absolute" }
      name              { "(s41) - Information provided in confidence" }
      abbreviation      { "conf" }
      sequence_id       { 560 }
    end

    trait :s44 do
      subtype           { "absolute" }
      name              { "(s44) - Prohibitions on disclosure" }
      abbreviation      { "prohib" }
      sequence_id       { 570 }
    end

    trait :s22 do
      subtype           { "qualified" }
      name              { "(s22) - Information intended for future publication" }
      abbreviation      { "future" }
      sequence_id       { 605 }
    end

    trait :s22a do
      subtype           { "qualified" }
      name              { "(s22A) - Research intended for future publication" }
      abbreviation      { "research" }
      sequence_id       { 610 }
    end

    trait :s24 do
      subtype           { "qualified" }
      name              { "(s24) - National security" }
      abbreviation      { "natsec" }
      sequence_id       { 615 }
    end

    trait :s26 do
      subtype           { "qualified" }
      name              { "(s26) - Defence" }
      abbreviation      { "defence" }
      sequence_id       { 620 }
    end

    trait :s27 do
      subtype           { "qualified" }
      name              { "(s27) - International relations" }
      abbreviation      { "intrel" }
      sequence_id       { 625 }
    end

    trait :s28 do
      subtype           { "qualified" }
      name              { "(s28) - Relations within the United Kingdom" }
      abbreviation      { "ukrel" }
      sequence_id       { 630 }
    end

    trait :s29 do
      subtype           { "qualified" }
      name              { "(s29) - The economy" }
      abbreviation      { "economy" }
      sequence_id       { 635 }
    end

    trait :s30 do
      subtype           { "qualified" }
      name              { "(s30) - Investigations and proceedings conducted by public authorities" }
      abbreviation      { "pubauth" }
      sequence_id       { 640 }
    end

    trait :s31 do
      subtype           { "qualified" }
      name              { "(s31) - Law enforcement" }
      abbreviation      { "law" }
      sequence_id       { 645 }
    end

    trait :s33 do
      subtype           { "qualified" }
      name              { "(s33) - Audit functions" }
      abbreviation      { "audit" }
      sequence_id       { 650 }
    end

    trait :s35 do
      subtype           { "qualified" }
      name              { "(s35) - Formulation of government policy" }
      abbreviation      { "policy" }
      sequence_id       { 655 }
    end

    trait :s36 do
      subtype           { "qualified" }
      name              { "(s36) - Prejudice to effective conduct of public affairs" }
      abbreviation      { "prej" }
      sequence_id       { 660 }
    end

    trait :s37 do
      subtype           { "qualified" }
      name              { "(s37) - Communication with Her Majesty, etc. and honours" }
      abbreviation      { "royals" }
      sequence_id       { 665 }
    end

    trait :s38 do
      subtype           { "qualified" }
      name              { "(s38) - Health and safety" }
      abbreviation      { "elf" }
      sequence_id       { 670 }
    end

    trait :s39 do
      subtype           { "qualified" }
      name              { "(s39) - Environment information" }
      abbreviation      { "env" }
      sequence_id       { 675 }
    end

    trait :s42 do
      subtype           { "qualified" }
      name              { "(s42) - Legal professional privilege" }
      abbreviation      { "legpriv" }
      sequence_id       { 680 }
    end

    trait :s43 do
      subtype           { "qualified" }
      name              { "(s43) - Commercial interests" }
      abbreviation      { "comm" }
      sequence_id       { 685 }
    end

    factory :outcome, class: "CaseClosure::Outcome" do
      subtype { nil }

      trait :requires_refusal_reason do
        name                      { "Generic outcome" }
        abbreviation              { "outcome" }
        requires_refusal_reason   { true }
      end

      trait :granted do
        name                      { "Granted in full" }
        abbreviation              { "granted" }
        sequence_id               { 10 }
      end

      trait :part_refused do
        name                      { "Refused in part" }
        abbreviation              { "part" }
        sequence_id               { 20 }
        requires_refusal_reason   { true }
      end

      trait :refused do
        name                      { "Refused fully" }
        abbreviation              { "refused" }
        sequence_id               { 30 }
        requires_refusal_reason   { true }
      end

      trait :clarify do
        name                      { "Clarification needed - Section 1(3)" }
        abbreviation              { "clarify" }
        sequence_id               { 15 }
      end
    end

    factory :refusal_reason, class: "CaseClosure::RefusalReason" do
      subtype { nil }

      trait :requires_exemption do
        name                        { "generic refusal reason" }
        abbreviation                { "genrefusal" }
        requires_exemption          { true }
      end

      trait :tmm do
        name                        { "(s1(3)) - Clarification required" }
        abbreviation                { "tmm" }
        sequence_id                 { 100 }
        requires_exemption          { false }
      end

      trait :sar_tmm do
        name                        { "SAR Clarification/Tell Me More" }
        abbreviation                { "sartmm" }
        sequence_id                 { 105 }
        requires_exemption          { false }
      end

      trait :exempt do
        name                        { "Exemption applied" }
        abbreviation                { "exempt" }
        sequence_id                 { 110 }
        requires_exemption          { true }
      end

      trait :noinfo do
        name                        { "Information not held" }
        abbreviation                { "noinfo" }
        sequence_id                 { 120 }
        requires_exemption          { false }
      end

      trait :notmet do
        name                        { "s8(1) - Conditions for submitting request not met" }
        abbreviation                { "notmet" }
        sequence_id                 { 130 }
        requires_exemption          { false }
      end

      trait :cost do
        name                        { "(s12(2)) - Exceeded cost to investigate" }
        abbreviation                { "cost" }
        sequence_id                 { 140 }
        requires_exemption          { false }
      end

      trait :vex do
        name                        { "(s14(1)) - Vexatious" }
        abbreviation                { "vex" }
        sequence_id                 { 150 }
        requires_exemption          { false }
      end

      trait :repeat do
        name                        { "(s14(2)) - Repeated request" }
        abbreviation                { "repeat" }
        sequence_id                 { 160 }
        requires_exemption          { false }
      end

      trait :ncnd do
        name                        { "Neither confirm nor deny (NCND)" }
        abbreviation                { "ncnd" }
        sequence_id                 { 170 }
        requires_exemption          { true }
      end
    end

    factory :info_status, class: "CaseClosure::InfoHeldStatus" do
      subtype                       { nil }
      requires_refusal_reason       { false }
      requires_exemption            { false }
      active                        { true }
      omit_for_part_refused         { false }

      trait :held do
        name                        { "Yes" }
        abbreviation                { "held" }
        sequence_id                 { 710 }
      end

      trait :not_held do
        name                        { "No" }
        abbreviation                { "not_held" }
        sequence_id                 { 730 }
      end

      trait :part_held do
        name                        { "Held in part" }
        abbreviation                { "part_held" }
        sequence_id                 { 720 }
      end

      trait :ncnd do
        name                        { "Other" }
        abbreviation                { "not_confirmed" }
        sequence_id                 { 740 }
      end
    end
  end

  factory :appeal_outcome, class: "CaseClosure::AppealOutcome" do
    subtype                       { nil }

    trait :upheld do
      name                        { "upheld" }
      abbreviation                { "Upheld" }
      sequence_id                 { 40 }
    end

    trait :upheld_in_part do
      name                        { "upheld_in_part" }
      abbreviation                { "Upheld in part" }
      sequence_id                 { 50 }
    end

    trait :overturned do
      name                        { "Overturned" }
      abbreviation                { "overturned" }
      sequence_id                 { 60 }
    end
  end

  factory :outcome_reason, class: "CaseClosure::OutcomeReason" do
    subtype                       { nil }

    trait :missing_info do
      name { "Proper searches not carried out/missing information" }
      abbreviation { "missing_info" }
      sequence_id { 900 }
    end

    trait :wrong_exemp do
      name { "Incorrect exemption engaged" }
      abbreviation { "wrong_exemp" }
      sequence_id { 905 }
    end

    trait :excess_redacts do
      name { "Excessive redaction(s)" }
      abbreviation { "excess_redacts" }
      sequence_id { 910 }
    end
  end

  factory :offender_complaint_outcome, class: "CaseClosure::OffenderComplaintOutcome" do
    subtype { nil }

    trait :succeeded do
      name                        { "Yes" }
      abbreviation                { "succeeded" }
      sequence_id                 { 900 }
    end

    trait :not_succeeded do
      name                        { "No" }
      abbreviation                { "not_succeeded" }
      sequence_id                 { 910 }
    end

    trait :settled do
      name                      { "Settled" }
      abbreviation              { "settled" }
      sequence_id               { 920 }
    end
  end

  factory :offender_complaint_appeal_outcome, class: "CaseClosure::OffenderComplaintAppealOutcome" do
    subtype { nil }

    trait :upheld do
      name                        { "Complaint upheld" }
      abbreviation                { "upheld" }
      sequence_id                 { 800 }
    end

    trait :not_upheld do
      name                        { "Complaint not upheld" }
      abbreviation                { "not_upheld" }
      sequence_id                 { 810 }
    end

    trait :not_response_received do
      name                      { "No ICO response received" }
      abbreviation              { "not_response_received" }
      sequence_id               { 820 }
    end
  end

  factory :offender_ico_complaint_approval_flag, class: "CaseClosure::ApprovalFlag::ICOOffenderComplaint" do
    subtype { nil }

    trait :first_approval do
      name                        { "Has this had Branston operations approval?" }
      abbreviation                { "first_approval" }
      sequence_id                 { 1000 }
    end

    trait :second_approval do
      name                        { "Has this had deputy director information services approval?" }
      abbreviation                { "second_approval" }
      sequence_id                 { 1010 }
    end

    trait :no_approval_required do
      name                      { "No approval needed" }
      abbreviation              { "no_approval_required" }
      sequence_id               { 1020 }
    end
  end

  factory :offender_litigation_complaint_approval_flag, class: "CaseClosure::ApprovalFlag::LitigationOffenderComplaint" do
    subtype { nil }

    trait :fee_approval do
      name                        { "Has this had fee approval?" }
      abbreviation                { "fee_approval" }
      sequence_id                 { 1100 }
    end
  end
end
