# == Schema Information
#
# Table name: report_types
#
#  id                       :integer          not null, primary key
#  abbr                     :string           not null
#  full_name                :string           not null
#  class_name               :string           not null
#  custom_report            :boolean          default(FALSE)
#  seq_id                   :integer          not null
#  foi                      :boolean          default(FALSE)
#  sar                      :boolean          default(FALSE)
#  standard_report          :boolean          default(FALSE), not null
#  default_reporting_period :string           default("year_to_date")
#

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')

RSpec.describe ReportType, type: :model do

  before(:each) do
    ReportType.destroy_all
  end

  after(:all) { ReportType.delete_all }

  it { should have_many(:reports) }

  describe 'custom scope' do

    it 'returns only closed cases in most recently closed first' do
      create :report_type
      custom_report_1 = create :report_type, custom_report: true
      custom_report_2 = create :report_type, custom_report: true
      expect(ReportType.custom).to match_array [ custom_report_1, custom_report_2 ]
    end
  end

  describe 'standard scope' do

    it 'returns only closed cases in most recently closed first' do
      create :report_type
      custom_report_1 = create :report_type, standard_report: true
      custom_report_2 = create :report_type, standard_report: true
      expect(ReportType.standard).to match_array [ custom_report_1, custom_report_2 ]
    end
  end

  describe 'foi scope' do

    it 'returns only reports associated with fois' do
      create :report_type
      custom_report_1 = create :report_type, foi: true
      custom_report_2 = create :report_type, foi: false
      expect(ReportType.foi).to match_array [ custom_report_1 ]
      expect(ReportType.foi).not_to include custom_report_2

    end
  end

  describe 'sar scope' do

    it 'returns only reports associated with sars' do
      create :report_type
      custom_report_1 = create :report_type, sar: true
      custom_report_2 = create :report_type, sar: false
      expect(ReportType.sar).to match_array [ custom_report_1 ]
      expect(ReportType.sar).not_to include custom_report_2

    end
  end

  describe '#class_constant' do
    it 'returns the report class name as a constant' do
      r003 = find_or_create :report_type, :r003
      expect(r003.class_constant)
        .to eq Stats::R003BusinessUnitPerformanceReport
    end
  end

  describe '#filename' do
    it 'formats the class name into a filename' do
      r003 = find_or_create :report_type, :r003
      expect(r003.filename('csv')).to eq 'r003_business_unit_performance_report.csv'
    end
  end


  describe '.method missing'  do
    context 'method is a report abbreviation' do
      it 'calls find_by' do
        expect(ReportType).to receive(:find_by!).with(abbr: 'R002')
        ReportType.r002
      end
    end

    context 'method is not a report abbreviation' do
      it 'raises NoMethodError' do
        expect {
          ReportType.rogue_method
        }.to raise_error NoMethodError, /undefined method `rogue_method' for/
      end
    end

    context '#file_extension' do
      it 'assumes csv only if concrete class does not support xlsx' do
        r006 = find_or_create :report_type, :r006
        expect(r006.file_extension).to eq 'csv'
      end
    end

    context '#description' do
      it 'returns concrete class description' do
        r003 = find_or_create :report_type, :r003
        expect(r003.description)
          .to eq Stats::R003BusinessUnitPerformanceReport.description
      end
    end
  end
  
end

