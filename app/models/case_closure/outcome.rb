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
  class Outcome < Metadatum

    def self.id_from_name(name)
      self.where(name: name).first&.id
    end

  end
end
