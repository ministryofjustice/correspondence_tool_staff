require 'rails_helper'

RSpec.describe Report, type: :model do
  describe 'report_type_id' do
    it { should belong_to(:report_type) }
  end

  describe 'mandatory fields' do
    it 'should require the following fields' do
      should validate_presence_of(:report_type_id)
      should validate_presence_of(:period_start)
      should validate_presence_of(:period_end)
      should validate_presence_of(:report_data)
    end
  end

end
