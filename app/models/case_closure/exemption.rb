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
  class Exemption < Metadatum

    SECTION_NUMBERS = {
      's12'   => 'cost',
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
      's44'   => 'prohib',
      'ncnd'  => 'ncnd'
    }.freeze

    ABBREVIATIONS = SECTION_NUMBERS.invert.freeze

    validates :subtype, presence: true

    scope :ncnd, -> { where(subtype: 'ncnd') }
    scope :absolute, -> { where(subtype: 'absolute') }
    scope :qualified, -> { where(subtype: 'qualified') }
    scope :absolute_for_partly_refused, -> { where.not(abbreviation: 'cost') }

    def self.method_missing(method, *args)
      # process self.s21 to self.s40
      if method.to_s.in?(SECTION_NUMBERS.keys)
        where(abbreviation: SECTION_NUMBERS[method.to_s]).first
      else
        super(method, args)
      end
    end

    def self.respond_to_missing?(method, include_private = false)
      method.to_s.in?(SECTION_NUMBERS.keys) || super
    end

    def ncnd?
      subtype == 'ncnd'
    end

    def self.most_frequently_used
      self.unscoped.where(abbreviation: %w{ pers othermeans court future }).order(:name)
    end

    def self.section_number_from_id(abbreviation)
      ABBREVIATIONS[abbreviation]
    end
  end
end
