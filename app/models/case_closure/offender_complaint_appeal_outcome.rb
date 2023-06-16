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
  class OffenderComplaintAppealOutcome < Metadatum
    def self.upheld
      where(abbreviation: "upheld").singular
    end

    def self.not_upheld
      where(abbreviation: "not_upheld").singular
    end

    def self.not_response_received
      where(abbreviation: "not_response_received").singular
    end

    def upheld?
      abbreviation == "upheld"
    end

    def not_upheld?
      abbreviation == "not_upheld"
    end

    def not_response_received?
      abbreviation == "not_response_received"
    end
  end
end
