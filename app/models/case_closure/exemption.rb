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
#

module CaseClosure
  class Exemption < Metadatum

    validates :subtype, presence: true

    scope :ncnd, -> { where(subtype: 'ncnd') }
    scope :absolute, -> { where(subtype: 'absolute') }
    scope :qualified, -> { where(subtype: 'qualified') }

    def self.s21
      abbrev('othermeans')
    end

    def self.s22
      abbrev('future')
    end

    def self.s22a
      abbrev('research')
    end

    def self.s23
      abbrev('security')
    end

    def self.s24
      abbrev('natsec')
    end

    def self.s26
      abbrev('defence')
    end

    def self.s27
      abbrev('intrel')
    end

    def self.s28
      abbrev('ukrel')
    end

    def self.s29
      abbrev('economy')
    end

    def self.s30
      abbrev('pubauth')
    end

    def self.s31
      abbrev('law')
    end

    def self.s32
      abbrev('court')
    end

    def self.abbrev(abbreviation)
      where(abbreviation: abbreviation).first
    end


    private_class_method :abbrev


    def ncnd?
      subtype == 'ncnd'
    end

  end
end
