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
  class AppealOutcome < Metadatum
    def self.upheld
      where(abbreviation: "upheld").singular
    end

    def self.upheld_in_part
      where(abbreviation: "upheld_part").singular
    end

    def self.overturned
      where(abbreviation: "overturned").singular
    end

    def upheld?
      abbreviation == "upheld"
    end

    def upheld_in_part?
      abbreviation == "upheld_part"
    end

    def overturned?
      abbreviation == "overturned"
    end
  end
end
