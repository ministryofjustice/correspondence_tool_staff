require 'rails_helper'

module CommissioningDocumentTemplate
  class TestClass < CommissioningDocumentTemplate::Base
    def context
      super.merge(deadline: deadline(5))
    end
  end
end

RSpec.describe CommissioningDocumentTemplate::TestClass do
  let(:kase) { build(:offender_sar_case) }
  let(:data_request) { build(:data_request, offender_sar_case: kase) }
  subject { described_class.new(data_request: data_request) }

  describe 'deadlines' do
    it 'sets deadline to next working day' do
      Timecop.freeze(Date.new(2022, 11, 15)) do # Tuesday
        expect(subject.context[:deadline]).to eq '21/11/2022' # Monday
      end

      Timecop.freeze(Date.new(2022, 11, 18)) do # Friday
        expect(subject.context[:deadline]).to eq '23/11/2022' # Wednesday
      end

      Timecop.freeze(Date.new(2022, 8, 22)) do # Monday
        expect(subject.context[:deadline]).to eq '30/08/2022' # Tuesday after bank holiday
      end
    end
  end
end
