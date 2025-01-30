require "rails_helper"

RSpec.describe CommissioningDocumentTemplate::Standard do
  subject(:template) { described_class.new(data_request_area:, deadline:) }

  let(:kase) do
    create(:offender_sar_case,
            case_reference_number: "CRN999",
            subject_full_name: "Robert Badson",
            date_of_birth: "2000-03-11",
            prison_number: "AB12345",
            subject_aliases: "Mr Blobby",
            other_subject_ids: "XYZ98765")
  end

  let(:data_request) do
    create(:data_request,
            request_type: "all_prison_records",
            request_type_note: "More info",
            date_from: Date.new(2024, 1, 1),
            date_to: Date.new(2024, 8, 8))
  end

  let(:completed_data_request) do
    create(:data_request,
            completed: true,
            cached_date_received: Date.current,
            request_type: "security_records",
            request_type_note: "security info",
            date_from: Date.new(2024, 1, 1),
            date_to: Date.new(2024, 8, 8))
  end

  let(:data_request_area) do
    create(:data_request_area,
            offender_sar_case: kase,
            data_requests: [data_request, completed_data_request])
  end
  let(:deadline) { Date.new(2022, 10, 26) }

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
          aliases: "Mr Blobby",
          crn: "CRN999",
          dpa_reference: kase.number,
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          pnc: "XYZ98765",
          prison_numbers: "AB12345",
          deadline: "26/10/2022",
          request_info: [
            {
              request_type: "All prison records",
              request_type_note: "More info",
              date_from: "01/01/2024",
              date_to: "08/08/2024",
            },
          ],
          requests: [
            {
              request_type: "All prison records",
            },
          ],
          request_additional_info: "",
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with optional values omitted" do
      let(:data_request) { create(:data_request, request_type: "all_prison_records") }

      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          aliases: "Mr Blobby",
          crn: "CRN999",
          dpa_reference: kase.number,
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          pnc: "XYZ98765",
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
          request_additional_info: "",
        }
      end

      it "populates data from the data_request_area and case" do
        Timecop.freeze(Date.new(2022, 10, 21)) do
          expect(template.context).to eq expected_context
        end
      end
    end

    context "with multiple requests" do
      let(:data_request_two) { create(:data_request, request_type: "cat_a") }
      let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, data_request_area_type: "prison", data_requests: [data_request, data_request_two, completed_data_request]) }

      let(:expected_context) do
        {
          addressee_location: "HMP halifax",
          aliases: "Mr Blobby",
          crn: "CRN999",
          dpa_reference: kase.number,
          offender_name: "Robert Badson",
          date_of_birth: "11/03/2000",
          date: "21/10/2022",
          pnc: "XYZ98765",
          prison_numbers: "AB12345",
          deadline: "26/10/2022",
          request_info: [
            {
              request_type: "All prison records",
              request_type_note: "More info",
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
          request_additional_info: "",
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
          request_type_note: "More info",
          date_from: "01/01/2024",
          date_to: "08/08/2024",
        },
      ]

      expect(template.request_info).to eq(expected_request_info)
    end

    context "with multiple requests" do
      let(:data_request_two) do
        create(:data_request,
                request_type: "cat_a",
                request_type_note: "CAT A info",
                date_from: Date.new(2024, 5, 1),
                date_to: Date.new(2024, 6, 1))
      end

      let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_two, completed_data_request]) }

      it "returns the correct information" do
        expected_request_info = [
          {
            request_type: "All prison records",
            request_type_note: "More info",
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
        create(:data_request,
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
      let(:data_request_two) { create(:data_request, request_type: "cat_a") }
      let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_two, completed_data_request]) }

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

  describe "#request_additional_info" do
    let(:data_request) { create(:data_request, request_type: "cctv") }

    it "returns the correct additional info for a request_type" do
      expected_info = "When providing the footage please supply an up-to-date photograph of the data subject and confirm the data you are sending us contains that same person. We cannot proceed without you verifying this.\nIf you have access to a Teams channel, please send the footage in MP4 format where possible.\n"
      expect(template.request_additional_info).to eq(expected_info)
    end

    context "with multiple requests" do
      let(:data_request) { create(:data_request, request_type: "cctv") }
      let(:data_request_two) { create(:data_request, request_type: "telephone_recordings") }
      let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_two, completed_data_request]) }

      it "returns the correct additional info for each request_type" do
        expected_info = "When providing the footage please supply an up-to-date photograph of the data subject and confirm the data you are sending us contains that same person. We cannot proceed without you verifying this.\nIf you have access to a Teams channel, please send the footage in MP4 format where possible.\n\nIf you have a transcript, please send this at the same time as the audio calls. If you do not have one we do not require you to create one.\n"
        expect(template.request_additional_info).to eq(expected_info)
      end
    end

    context "with request types that do not have additional info" do
      let(:data_request) { create(:data_request, request_type: "all_prison_records") }

      it "returns an empty string" do
        expect(template.request_additional_info).to eq ""
      end
    end

    context "with multiple of the same request_type" do
      let(:data_request) { create(:data_request, request_type: "cctv") }
      let(:data_request_two) { create(:data_request, request_type: "cctv") }
      let(:data_request_area) { create(:data_request_area, offender_sar_case: kase, data_requests: [data_request, data_request_two, completed_data_request]) }

      it "returns only 1 instance of the additional info" do
        expected_info = "When providing the footage please supply an up-to-date photograph of the data subject and confirm the data you are sending us contains that same person. We cannot proceed without you verifying this.\nIf you have access to a Teams channel, please send the footage in MP4 format where possible.\n"
        expect(template.request_additional_info).to eq(expected_info)
      end
    end
  end
end
