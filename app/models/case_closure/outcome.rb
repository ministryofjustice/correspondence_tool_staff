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
  class Outcome < Metadatum
    def self.granted
      where(abbreviation: "granted").singular
    end

    def self.part_refused
      where(abbreviation: "part").singular
    end

    def self.fully_refused
      where(abbreviation: "refused").singular
    end

    def self.clarify
      where(abbreviation: "clarify").singular
    end

    def granted?
      abbreviation == "granted"
    end

    def part_refused?
      abbreviation == "part"
    end

    def fully_refused?
      abbreviation == "refused"
    end
  end
end
