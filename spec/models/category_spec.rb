require 'rails_helper'

RSpec.describe Category, type: :model do

  let(:category) { create(:category) }

  it do
    should validate_presence_of(:name)
    should validate_presence_of(:abbreviation)
    should validate_presence_of(:internal_time_limit)
    should validate_presence_of(:external_time_limit)
    should have_many(:correspondence)
  end

end
