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

    SECTION_NUMBERS = {
      's21'   => 'othermeans',
      's22'   => 'future',
      's22a'  => 'research',
      's23'   => 'security',
      's24'   => 'natsec',
      's26'   => 'defence',
      's27'   => 'intrel',
      's28'   => 'ukrel',
      's29'   => 'economy',
      's30'   => 'pubauth',
      's31'   => 'law',
      's32'   => 'court',
      's33'   => 'audit',
      's34'   => 'pp',
      's35'   => 'policy',
      's36'   => 'prej',
      's37'   => 'royals',
      's38'   => 'elf',
      's39'   => 'env',
      's40'   => 'pers',
      's41'   => 'conf',
      's42'   => 'legpriv',
      's43'   => 'comm',
      's44'   => 'prohib'
    }.freeze

    validates :subtype, presence: true

    scope :ncnd, -> { where(subtype: 'ncnd') }
    scope :absolute, -> { where(subtype: 'absolute') }
    scope :qualified, -> { where(subtype: 'qualified') }


    def self.method_missing(method)
      # process self.s21 to self.s40
      if method.to_s.in?(SECTION_NUMBERS.keys)
        where(abbreviation: SECTION_NUMBERS[method.to_s]).first
      else
        super
      end
    end

    # def self.s21
    #   abbrev('othermeans')
    # end
    #
    # def self.s22
    #   abbrev('future')
    # end
    #
    # def self.s22a
    #   abbrev('research')
    # end
    #
    # def self.s23
    #   abbrev('security')
    # end
    #
    # def self.s24
    #   abbrev('natsec')
    # end
    #
    # def self.s26
    #   abbrev('defence')
    # end
    #
    # def self.s27
    #   abbrev('intrel')
    # end
    #
    # def self.s28
    #   abbrev('ukrel')
    # end
    #
    # def self.s29
    #   abbrev('economy')
    # end
    #
    # def self.s30
    #   abbrev('pubauth')
    # end
    #
    # def self.s31
    #   abbrev('law')
    # end
    #
    # def self.s32
    #   abbrev('court')
    # end
    #
    # def self.s33
    #   abbrev('audit')
    # end
    #
    #
    #
    # def self.abbrev(abbreviation)
    #   where(abbreviation: abbreviation).first
    # end


    def ncnd?
      subtype == 'ncnd'
    end

  end
end
