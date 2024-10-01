require "rails_helper"

RSpec.describe CommissioningDocumentTemplate::Standard do
  subject(:template) { described_class.new(data_request_area:) }

  let(:kase) do
    build_stubbed(:offender_sar_case,
                  number: "20062007",
                  subject_full_name: "Robert Badson",
                  date_of_birth: "2000-03-11",
                  prison_number: "AB12345")
  end

  let(:data_request) do
    build_stubbed(:data_request,
                  request_type: "all_prison_records",
                  request_type_note: "more info",
                  date_from: Date.new(2024, 1, 1),
                  date_to: Date.new(2024, 8, 8))
  end

  let(:data_request_area) do
    build_stubbed(:data_request_area,
                  offender_sar_case: kase,
                  data_requests: [data_request])
  end

  describe "#path" do
    it "matches to a file" do
      expect(File).to exist(template.path)
    end
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
          deadline: "26/10/2022",
          request_info: [
            {
              request_type: "All prison records",
              request_type_note: "more info",
              date_from: "01/01/2024",
              date_to: "08/08/2024",
            },
          ],
          requests: [
            {
              request_type: "All prison records",
            },
          ],
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with optional values omitted" do
      let(:data_request) do
        build_stubbed(:data_request,
                      request_type: "all_prison_records")
      end
      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          deadline: "26/10/2022",
          request_info: [
            {
              request_type: "All prison records",
              request_type_note: "",
              date_from: nil,
              date_to: nil,
            },
          ],
          requests: [
            {
              request_type: "All prison records",
            },
          ],
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
                      request_type: "cat_a")
      end
      let(:data_request_area) { build_stubbed(:data_request_area, offender_sar_case: kase, data_request_area_type: "prison", data_requests: [data_request, data_request_2]) }

      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          dpa_reference: "20062007",
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          prison_numbers: "AB12345",
          deadline: "26/10/2022",
          request_info: [
            {
              request_type: "All prison records",
              request_type_note: "more info",
              date_from: "01/01/2024",
              date_to: "08/08/2024",
            },
            {
              request_type: "CAT A",
              request_type_note: "",
              date_from: nil,
              date_to: nil,
            },
          ],
          requests: [
            {
              request_type: "All prison records",
            },
            {
              request_type: "CAT A",
            },
          ],
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end
  end

  describe "#request_info" do
    it "returns the correct information" do
      expected_request_info = [
        {
          request_type: "All prison records",
          request_type_note: "more info",
          date_from: "01/01/2024",
          date_to: "08/08/2024",
        },
      ]

      expect(template.request_info).to eq(expected_request_info)
    end

    context "with multiple requests" do
      let(:data_request_2) do
        build_stubbed(:data_request,
                      request_type: "cat_a",
                      request_type_note: "CAT A info",
                      date_from: Date.new(2024, 5, 1),
                      date_to: Date.new(2024, 6, 1))
      end

      let(:data_request_area) { build_stubbed(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_2]) }

      it "returns the correct information" do
        expected_request_info = [
          {
            request_type: "All prison records",
            request_type_note: "more info",
            date_from: "01/01/2024",
            date_to: "08/08/2024",
          },
          {
            request_type: "CAT A",
            request_type_note: "CAT A info",
            date_from: "01/05/2024",
            date_to: "01/06/2024",
          },
        ]

        expect(template.request_info).to eq(expected_request_info)
      end
    end

    context "with optional values omitted" do
      let(:data_request) do
        build_stubbed(:data_request,
                      request_type: "all_prison_records",
                      request_type_note: "",
                      date_from: nil,
                      date_to: nil)
      end

      it "handles missing optional values" do
        expected_request_info = [
          {
            request_type: "All prison records",
            request_type_note: "",
            date_from: nil,
            date_to: nil,
          },
        ]

        expect(template.request_info).to eq(expected_request_info)
      end
    end
  end

  describe "#requests" do
    it "returns the correct request types" do
      expected_requests = [
        {
          request_type: "All prison records",
        },
      ]

      expect(template.requests).to eq(expected_requests)
    end

    context "with multiple requests" do
      let(:data_request_2) do
        build_stubbed(:data_request,
                      request_type: "cat_a")
      end

      let(:data_request_area) { build_stubbed(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_2]) }

      it "returns the correct request types" do
        expected_requests = [
          {
            request_type: "All prison records",
          },
          {
            request_type: "CAT A",
          },
        ]

        expect(template.requests).to eq(expected_requests)
      end
    end
  end
end
