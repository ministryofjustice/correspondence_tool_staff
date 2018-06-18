# == Schema Information
#
# Table name: reports
#
#  id             :integer          not null, primary key
#  report_type_id :integer          not null
#  period_start   :date
#  period_end     :date
#  report_data    :binary
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe Report, type: :model do
  describe 'report_type_id' do
    it { should belong_to(:report_type) }
  end

  describe 'mandatory fields' do
    it 'should require the following fields' do
      should validate_presence_of(:report_type_id)
    end
  end

  describe '#report_type_abbr=' do
    it 'finds a report_type by abbreviation' do
      r003_report_type = find_or_create(:r003_report_type)
      report = Report.new(report_type_abbr: 'R003')
      expect(report.report_type_id).to eq r003_report_type.id
    end
  end

  describe '#period_start' do
    let(:tomorrow) { build(:report, period_start: Date.tomorrow.to_s) }
    let(:today)    { build(:report, period_start: Date.today.to_s,
                                    period_end: Date.today.to_s) }
    let(:yesterday) { build(:report, period_start: Date.yesterday.to_s,
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
    let(:tomorrow) { build_stubbed(:report, period_end: Date.tomorrow.to_s) }
    let(:today)    { build_stubbed(:report, period_start: Date.today.to_s,
                                    period_end: Date.today.to_s)}
    let(:yesterday) { build_stubbed(:report, period_end: Date.yesterday.to_s) }

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

  describe '#run' do
    let(:args)           { [Date.yesterday, Date.today] }
    let(:report_service) { instance_double(
                             Stats::R003BusinessUnitPerformanceReport,
                             to_csv: 'report,data',
                             period_start: Date.yesterday,
                             period_end: Date.today,
                             run: true
                           ) }
    let(:report)         { build_stubbed :r003_report }

    before do
      expect(Stats::R003BusinessUnitPerformanceReport)
        .to receive(:new).with(*args).and_return(report_service)
    end

    it 'instantiates and runs a report' do
      update_params = { report_data: instance_of(String),
                        period_start: Date.yesterday,
                        period_end: Date.today
      }
      expect(report).to receive(:update!).with(update_params)
      report.run(*args)
      expect(report_service).to have_received(:run)
    end

    it 'updates start and end dates' do
      report.run(*args)
      expect(report.period_start).to eq Date.yesterday
      expect(report.period_end).to   eq Date.today
    end

    it 'updates the report_data' do
      report.run(*args)
      expect(report.report_data).to eq 'report,data'
    end
  end

  describe '#trim_older_reports' do
    it 'removes reports of the same type' do
      old_report = create :r003_report
      report = create :r003_report
      report.trim_older_reports
      expect(Report.where(id: old_report.id)).to be_blank
    end

    it 'does not remove other reports' do
      other_report = create :r004_report
      report = create :r003_report
      report.trim_older_reports
      expect(Report.find(other_report.id)).to be_present
    end
  end
end
