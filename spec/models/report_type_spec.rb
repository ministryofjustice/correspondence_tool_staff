# == Schema Information
#
# Table name: report_types
#
#  id            :integer          not null, primary key
#  abbr          :string           not null
#  full_name     :string           not null
#  class_name    :string           not null
#  custom_report :boolean          default(FALSE)
#  seq_id        :integer          not null
#

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

  describe '#filename' do
    it 'formats the class name into a filename' do
      r003 = find_or_create :r003_report_type
      expect(r003.filename).to eq 'r003_business_unit_performance_report.csv'
    end
  end
end
