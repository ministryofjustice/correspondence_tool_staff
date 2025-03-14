require "rails_helper"

describe DataRequestDecorator, type: :model do
  describe "#request_dates" do
    let(:decorated) { find_or_create(:data_request).decorate }

    context "with only a from date" do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 8, 20)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "from 20/08/2022 to date"
      end
    end

    context "with only a to date" do
      let(:decorated) { find_or_create(:data_request, date_to: Date.new(2022, 12, 13)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "up to 13/12/2022"
      end
    end

    context "with both from and to dates" do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 12, 13), date_to: Date.new(2022, 12, 13)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "from 13/12/2022 to 13/12/2022"
      end
    end

    context "with neither to or from dates" do
      it "returns an empty string" do
        expect(decorated.request_dates).to eq ""
      end
    end
  end

  describe "#location" do
    let(:offender_sar_case) { create(:offender_sar_case) }
    let(:data_request_area) { create(:data_request_area, offender_sar_case:, contact: nil, location: "Original Location") }
    let(:data_request) { create(:data_request, offender_sar_case:, data_request_area:) }
    let(:decorated) { data_request.decorate }

    context "without linked contact" do
      it "falls back to data_request_area location string" do
        expect(decorated.location).to eq "Original Location"
      end
    end

    context "with linked contact" do
      let(:contact) { create(:contact, name: "Test Organisation") }

      before do
        data_request_area.update!(contact:)
      end

      it "uses the name of the contact" do
        expect(decorated.location).to eq "Test Organisation"
      end
    end
  end

  describe "#data_required" do
    context "when request_type = other" do
      let(:data_request) { create(:data_request, request_type: "other", request_type_note: "some information") }
      let(:decorated) { data_request.decorate }

      it "uses what data is needed string" do
        expect(decorated.data_required).to eq data_request.request_type_note
      end
    end

    context "when request_type != other" do
      let(:data_request) { create(:data_request) }
      let(:decorated) { data_request.decorate }

      it "uses what data is needed string" do
        expect(decorated.data_required).to be_nil
      end
    end
  end

  describe "#display_request_type_note?" do
    it "returns true when request_type_note is present" do
      data_request = create(:data_request, request_type_note: "note")
      expect(data_request.decorate).to be_display_request_type_note
    end

    it "returns false when request_type_note is blank" do
      data_request = create(:data_request, request_type_note: "")
      expect(data_request.decorate).not_to be_display_request_type_note
    end
  end

  describe "#data_request_status_tag" do
    context "when status is :completed" do
      let(:decorated) { create(:data_request, completed: true, cached_date_received: 1.day.ago).decorate }

      it 'returns a green "Completed" tag' do
        expect(decorated.data_request_status_tag)
          .to eq("<strong class='govuk-tag govuk-tag--green'>Completed</strong>")
      end
    end

    context "when status is :in_progress" do
      let(:decorated) { create(:data_request).decorate }

      it 'returns a yellow "In progress" tag' do
        expect(decorated.data_request_status_tag)
          .to eq("<strong class='govuk-tag govuk-tag--yellow'>In progress</strong>")
      end
    end
  end
end
