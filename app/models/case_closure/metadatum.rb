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

class CaseClosure::Metadatum < ApplicationRecord

  self.table_name = :case_closure_metadata

  default_scope { order(:sequence_id) }

  validates :name, :abbreviation, :sequence_id, presence: true

end
