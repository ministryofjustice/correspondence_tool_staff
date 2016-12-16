require 'rails_helper'

RSpec.describe Category, type: :model do

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:abbreviation) }
  it { should validate_presence_of(:escalation_time_limit) }
  it { should validate_presence_of(:internal_time_limit) }
  it { should validate_presence_of(:external_time_limit) }
  it { should have_many(:cases) }
end
