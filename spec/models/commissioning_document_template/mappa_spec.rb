require "rails_helper"

RSpec.describe CommissioningDocumentTemplate::Mappa do
  subject(:template) { described_class.new(data_request_area:, deadline:) }

  let(:kase) do
    build_stubbed(:offender_sar_case,
                  number: "20062007",
                  subject_full_name: "Robert Badson",
                  date_of_birth: "2000-03-11",
                  subject_aliases: "Bad Bob",
                  prison_number: "AB12345",
                  other_subject_ids: "CD98765")
  end
  let(:data_request_area) { build_stubbed(:data_request_area, offender_sar_case: kase) }
  let(:deadline) { Date.new(2022, 11, 10) }

  describe "#path" do
    it "matches to a file" do
      expect(File).to exist(template.path)
    end
  end

  describe "#context" do
    context "without dates" do
      let(:expected_context) do
        {
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date_range: "",
          aliases: "Bad Bob",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          pnc: "CD98765",
          deadline: "10/11/2022",
        }
      end

      it "populates data from the data_request and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with dates" do
      let(:data_request_area) do
        build_stubbed(:data_request,
                      offender_sar_case: kase,
                      date_from: Date.new(2024, 9, 1),
                      date_to: Date.new(2024, 9, 10)).decorate
      end
      let(:expected_context) do
        {
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date_range: "from 01/09/2024 to 10/09/2024",
          aliases: "Bad Bob",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          pnc: "CD98765",
          deadline: "10/11/2022",
        }
      end

      it "populates data from the data_request and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end
  end
end
