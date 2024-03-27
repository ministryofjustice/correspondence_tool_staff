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
module CaseClosure
  class OffenderComplaintOutcome < Metadatum
    def self.succeeded
      where(abbreviation: "succeeded").singular
    end

    def self.not_succeeded
      where(abbreviation: "not_succeeded").singular
    end

    def self.settled
      where(abbreviation: "settled").singular
    end

    def succeeded?
      abbreviation == "succeeded"
    end

    def not_succeeded?
      abbreviation == "not_succeeded"
    end

    def settled?
      abbreviation == "settled"
    end
  end
end
