require "rails_helper"

RSpec.describe CommissioningDocumentTemplate::Probation do
  subject(:template) { described_class.new(data_request_area:) }

  let(:kase) do
    build_stubbed(:offender_sar_case,
                  number: "20062007",
                  subject_full_name: "Robert Badson",
                  date_of_birth: "2000-03-11",
                  prison_number: "AB12345",
                  other_subject_ids: "CD98765",
                  case_reference_number: "EF45678")
  end

  let(:data_request) do
    build_stubbed(:data_request,
                  request_type: "probation_records",
                  request_type_note: "All paper and electronic information",
                  date_from: Date.new(2024, 2, 15),
                  date_to: Date.new(2024, 6, 30))
  end

  let(:data_request_area) do
    build_stubbed(:data_request_area,
                  offender_sar_case: kase,
                  data_requests: [data_request],
                  data_request_area_type: "probation",
                  location: "HMP halifax")
  end

  describe "#context" do
    context "with fully populated values" do
      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          pnc: "CD98765",
          crn: "EF45678",
          deadline: "26/10/2022",
          data_required: "All paper and electronic information",
          date_range: "from 15/02/2024 to 30/06/2024",
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with multiple requests" do
      let(:data_request_2) do
        build_stubbed(:data_request,
                      request_type: "probation_records",
                      request_type_note: "more info",
                      date_from: Date.new(2024, 2, 15),
                      date_to: Date.new(2024, 6, 30))
      end
      let(:data_request_area) do
        build_stubbed(:data_request_area,
                      offender_sar_case: kase,
                      data_request_area_type: "prison",
                      data_requests: [data_request, data_request_2])
      end

      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          pnc: "CD98765",
          crn: "EF45678",
          deadline: "26/10/2022",
          data_required: "All paper and electronic information\nmore info",
          date_range: "from 15/02/2024 to 30/06/2024\nfrom 15/02/2024 to 30/06/2024",
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with missing optional values" do
      let(:data_request) do
        build_stubbed(:data_request,
                      request_type: "probation_records",
                      request_type_note: "",
                      date_from: nil,
                      date_to: nil)
      end

      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          pnc: "CD98765",
          crn: "EF45678",
          deadline: "26/10/2022",
          data_required: "",
          date_range: "",
        }
      end

      it "handles missing optional values gracefully" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end
  end
end
