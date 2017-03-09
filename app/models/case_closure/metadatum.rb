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

class CaseClosure::Metadatum < ApplicationRecord

  self.table_name = :case_closure_metadata

  default_scope { order(:sequence_id) }

  validates :name, :abbreviation, :sequence_id, presence: true
  validates :name, :abbreviation, uniqueness: true

  def self.id_from_name(name)
    self.where(name: name).first&.id
  end

  def self.by_name(name)
    self.where(name: name).first
  end

end
