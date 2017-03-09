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

require 'rails_helper'

module CaseClosure
  RSpec.describe RefusalReason, type: :model do

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:abbreviation) }
    it { should validate_presence_of(:sequence_id) }

  end
end
