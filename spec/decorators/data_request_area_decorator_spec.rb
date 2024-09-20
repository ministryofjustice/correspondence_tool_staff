require "rails_helper"

describe DataRequestAreaDecorator, type: :model do
  let(:data_request_area) { create(:data_request_area) }

  describe "#location" do
    let(:data_request_area) { create(:data_request_area, contact: nil, location: "Original location") }
    let(:decorated) { data_request_area.decorate }

    context "without linked contact" do
      it "uses the data_request_area location attribute" do
        expect(decorated.location).to eq "Original location"
      end
    end

    context "with a linked contact" do
      let(:contact) { create(:contact, name: "Test Contact") }

      before do
        data_request_area.update!(contact:)
      end

      it "returns the contacts name" do
        expect(decorated.location).to eq "Test Contact"
      end
    end
  end

  describe "#num_of_requests" do
    let(:decorated) { data_request_area.decorate }

    it "returns the count of data_requests" do
      create_list(:data_request, 3, data_request_area:)

      expect(decorated.num_of_requests).to eq(3)
    end
  end

  describe "#cached_num_pages" do
    let(:decorated) { data_request_area.decorate }

    it "returns the sum of cached_num_pages for all data_requests" do
      create(:data_request, data_request_area:, cached_num_pages: 5)
      create(:data_request, data_request_area:, cached_num_pages: 10)

      expect(decorated.cached_num_pages).to eq(15)
    end
  end

  describe "#date_requested" do
    let(:decorated) { data_request_area.decorate }

    it "returns the earliest date_requested of the associated data_requests" do
      create(:data_request, data_request_area:, date_requested: 2.days.ago)
      create(:data_request, data_request_area:, date_requested: 1.day.ago)

      expect(decorated.date_requested).to eq(2.days.ago.to_date)
    end

    it "returns nil if there are no data_requests" do
      expect(decorated.date_requested).to be_nil
    end
  end

  describe "#date_completed" do
    let(:decorated) { data_request_area.decorate }

    context "when all data_requests are completed" do
      it "returns the latest cached_date_received" do
        create(:data_request, :completed, data_request_area:, cached_date_received: 3.days.ago)
        create(:data_request, :completed, data_request_area:, cached_date_received: 1.day.ago)

        expect(decorated.date_completed).to eq(1.day.ago.to_date)
      end
    end

    context "when not all data_requests are completed" do
      it "returns an empty string" do
        create(:data_request, data_request_area:)

        expect(decorated.date_completed).to eq(nil)
      end
    end
  end

  describe "#request_document" do
    let(:decorated) { data_request_area.decorate }
    let!(:commissioning_document) { create :commissioning_document, data_request_area: }

    it "displays the current request document" do
      # TODO: update during the chase work to use the relevant stage
      expect(decorated.request_document).to eq("Day 1 commissioning")
    end
  end

  describe "#data_request_area_status_tag" do
    let(:decorated) { data_request_area.decorate }

    context "when status is :completed" do
      it 'returns a green "Completed" tag' do
        expect(decorated.data_request_area_status_tag(:completed))
          .to eq("<strong class='govuk-tag govuk-tag--green'>Completed</strong>")
      end
    end

    context "when status is :in_progress" do
      it 'returns a yellow "In progress" tag' do
        expect(decorated.data_request_area_status_tag(:in_progress))
          .to eq("<strong class='govuk-tag govuk-tag--yellow'>In progress</strong>")
      end
    end

    context "when status is :not_started" do
      it 'returns a red "Not started" tag' do
        expect(decorated.data_request_area_status_tag(:not_started))
          .to eq("<strong class='govuk-tag govuk-tag--red'>Not started</strong>")
      end
    end
  end
end
