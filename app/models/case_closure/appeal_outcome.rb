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
#  required_for_refused    :boolean          default(FALSE)
#  required_for_ncnd       :boolean          default(FALSE)
#

module CaseClosure
  class AppealOutcome < Metadatum
    def self.upheld
      where(abbreviation: 'upheld').singular
    end

    def self.upheld_in_part
      where(abbreviation: 'upheld_part').singular
    end

    def self.reversed
      where(abbreviation: 'reversed').singular
    end

    def upheld?
      abbreviation == 'upheld'
    end

    def upheld_in_part?
      abbreviation == 'upheld_part'
    end

    def reversed?
      abbreviation == 'reversed'
    end
  end
end
