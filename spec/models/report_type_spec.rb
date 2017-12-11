require 'rails_helper'

RSpec.describe ReportType, type: :model do


  it { should have_many(:reports) }

  describe 'custom scope' do

    before do
      ReportType.destroy_all
    end

    it 'returns only closed cases in most recently closed first' do
      create :report_type
      custom_report_1 = create :report_type, custom_report: true
      custom_report_2 = create :report_type, custom_report: true
      expect(ReportType.custom).to match_array [ custom_report_1, custom_report_2 ]
    end
  end
end
