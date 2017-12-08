require 'rails_helper'

describe ReportGeneratorJob do

  context 'R003' do
    it 'generates the report' do
      create :report_type, :r003
      ReportGeneratorJob.perform_now('R003')
    end
  end



end
