require "rails_helper"

module CommissioningDocumentTemplate
  class TestClass < CommissioningDocumentTemplate::Base
    def context
      super.merge(deadline: calculate_deadline(5))
    end
  end
end

RSpec.describe "CommissioningDocumentTemplate::TestClass" do
  subject(:template) { CommissioningDocumentTemplate::TestClass.new(data_request:) }

  let(:kase) { build_stubbed(:offender_sar_case) }
  let(:data_request) { build_stubbed(:data_request, offender_sar_case: kase) }

  describe "deadlines" do
    it "sets deadline to 5 days time", :aggregate_failures do
      Timecop.freeze(Date.new(2022, 11, 15)) do # Tuesday
        expect(template.context[:deadline]).to eq "20/11/2022" # Sunday
      end

      Timecop.freeze(Date.new(2022, 11, 18)) do # Friday
        expect(template.context[:deadline]).to eq "23/11/2022" # Wednesday
      end

      Timecop.freeze(Date.new(2022, 8, 22)) do # Monday
        expect(template.context[:deadline]).to eq "27/08/2022" # Saturday
      end
    end
  end
end
