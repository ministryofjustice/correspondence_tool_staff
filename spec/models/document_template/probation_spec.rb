require 'rails_helper'

RSpec.describe DocumentTemplate::Probation do
  let(:kase) do
    FactoryBot.build(:offender_sar_case,
      number: "20062007",
      subject_full_name: "Robert Badson",
      date_of_birth: "2000-03-11",
      prison_number: "AB12345",
      other_subject_ids: "CD98765",
      case_reference_number: "EF45678",
    )
  end
  let(:data_request) { FactoryBot.build(:data_request, offender_sar_case: kase) }
  subject { described_class.new(data_request: data_request) }

  describe "#path" do
    it "matches to a file" do
      expect(File).to exist(subject.path)
    end
  end

  describe "#context" do
    let(:expected_context) do
      {
        dpa_reference: "20062007",
        offender_name: "Robert Badson",
        date_of_birth: "11/03/2000",
        date: "21/10/2022",
        prison_numbers: "AB12345",
        deadline: "26/10/2022",
        pnc: "CD98765",
        crn: "EF45678",
      }
    end

    it "populates data from the data_request and case" do
      Timecop.freeze(Date.new(2022, 10, 21)) do
        expect(subject.context).to eq expected_context
      end
    end
  end
end
