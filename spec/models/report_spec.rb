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
    end
  end

  describe '#period_start' do
    let(:tomorrow)         { build(:report, period_start: Date.tomorrow.to_s) }
    let(:today)            { build(:report, period_start: Date.today.to_s,
                                   period_end: Date.today.to_s)}

    let(:yesterday)        { build(:report,
                                   period_start: Date.yesterday.to_s,
                                   period_end: Date.today.to_s) }

    let(:after_period_end) { build(:report, period_start: Date.today.to_s,
                                   period_end: Date.yesterday.to_s)}

    it 'cannot be in the future' do
      expect(tomorrow).to_not be_valid
    end

    it 'can be for today' do
      expect(today).to be_valid
    end

    it 'can be in the past' do
      expect(yesterday).to be_valid
    end

    it 'cannot after period end' do
      expect(after_period_end).to_not be_valid
    end
  end

  describe '#period_end' do
    let(:tomorrow) { build(:report, period_end: Date.tomorrow.to_s) }
    let(:today)    { build(:report, period_start: Date.today.to_s,
                                    period_end: Date.today.to_s)}
    let(:yesterday) { build(:report, period_end: Date.yesterday.to_s) }
                              # build(:case, received_date: Date.yesterday.to_s)

    it "can't be in the future" do
      expect(tomorrow).to_not be_valid
    end

    it "can be for today" do
      expect(today).to be_valid
    end

    it 'can be in the past' do
      expect(yesterday).to be_valid
    end
  end
end
