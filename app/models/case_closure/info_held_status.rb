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
  class InfoHeldStatus < Metadatum
    def self.held
      where(abbreviation: "held").singular
    end

    def self.not_held
      where(abbreviation: "not_held").singular
    end

    def self.part_held
      where(abbreviation: "part_held").singular
    end

    def self.not_confirmed
      where(abbreviation: "not_confirmed").singular
    end

    def self.id_from_abbreviation(abbrev)
      abbrev.nil? ? nil : find_by_abbreviation!(abbrev).id
    end

    def held?
      abbreviation == "held"
    end

    def not_held?
      abbreviation == "not_held"
    end

    def part_held?
      abbreviation == "part_held"
    end

    def not_confirmed?
      abbreviation == "not_confirmed"
    end
  end
end
