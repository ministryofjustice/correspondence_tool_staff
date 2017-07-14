# == Schema Inforails rmation
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

    def self.othermeans
      abbrev('othermeans')
    end

    def self.security
      abbrev('security')
    end

    def self.court
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
