require "rails_helper"

RSpec.describe CommissioningDocumentTemplate::Cctv do
  subject(:template) { described_class.new(data_request_area:, deadline:) }

  let(:kase) do
    build_stubbed(:offender_sar_case,
                  number: "20062007",
                  subject_full_name: "Robert Badson",
                  date_of_birth: "2000-03-11",
                  subject_aliases: "Bad Bob",
                  prison_number: "AB12345")
  end
  let(:data_request_area) { build_stubbed(:data_request_area, offender_sar_case: kase) }
  let(:deadline) { Date.new(2022, 10, 26) }

  describe "#path" do
    it "matches to a file" do
      expect(File).to exist(template.path)
    end
  end

  describe "#context" do
    let(:expected_context) do
      {
        addressee_location: "HMP halifax",
        dpa_reference: "20062007",
        offender_name: "Robert Badson",
        date_of_birth: "11/03/2000",
        aliases: "Bad Bob",
        date: "21/10/2022",
        prison_numbers: "AB12345",
        deadline: "26/10/2022",
      }
    end

    it "populates data from the data_request and case" do
      Timecop.freeze(Date.new(2022, 10, 21)) do
        expect(template.context).to eq expected_context
      end
    end
  end
end
