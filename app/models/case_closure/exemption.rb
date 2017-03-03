# == Schema Information
#
# Table name: case_closure_metadata
#
#  id           :integer          not null, primary key
#  type         :string
#  subtype      :string
#  name         :string
#  abbreviation :string
#  sequence_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

module CaseClosure
  class Exemption < Metadatum

    validates :subtype, presence: true

    scope :ncnd, -> { where(subtype: 'ncnd') }
    scope :absolute, -> { where(subtype: 'absolute') }
    scope :qualified, -> { where(subtype: 'qualified') }

  end
end
