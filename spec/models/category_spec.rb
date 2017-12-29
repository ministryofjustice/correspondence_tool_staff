# == Schema Information
#
# Table name: categories
#
#  id                    :integer          not null, primary key
#  name                  :string
#  abbreviation          :string
#  internal_time_limit   :integer
#  external_time_limit   :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  escalation_time_limit :integer
#

require 'rails_helper'

RSpec.describe Category, type: :model do

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:abbreviation) }
  it { should validate_presence_of(:escalation_time_limit) }
  it { should validate_presence_of(:internal_time_limit) }
  it { should validate_presence_of(:external_time_limit) }
end
