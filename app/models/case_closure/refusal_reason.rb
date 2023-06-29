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
  class RefusalReason < Metadatum
    scope :sar, -> { where(abbreviation: "sartmm") }
    scope :foi, -> { where.not(abbreviation: "sartmm") }

    def self.exempt
      abbrev("exempt")
    end

    def self.noinfo
      abbrev("noinfo")
    end

    def self.notmet
      abbrev("notmet")
    end

    def self.cost
      abbrev("cost")
    end

    def self.vex
      abbrev("vex")
    end

    def self.repeat
      abbrev("repeat")
    end

    def self.tmm
      abbrev("tmm")
    end

    def self.sar_tmm
      abbrev("sartmm")
    end

    def self.ncnd
      abbrev("ncnd")
    end

    def ncnd?
      abbreviation == "ncnd"
    end

    def self.abbrev(abbreviation)
      where(abbreviation:).first
    end

    private_class_method :abbrev
  end
end
