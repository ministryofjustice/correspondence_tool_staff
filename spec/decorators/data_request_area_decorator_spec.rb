require "rails_helper"

describe DataRequestAreaDecorator, type: :model do
  let(:data_request_area) { create(:data_request_area) }
  let(:decorated) { data_request_area.decorate }

  describe "#location" do
    let(:data_request_area) { create(:data_request_area, contact: nil, location: "Original location") }

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
    it "returns the count of data_requests" do
      create_list(:data_request, 3, data_request_area:)

      expect(decorated.num_of_requests).to eq(3)
    end
  end

  describe "#cached_num_pages" do
    it "returns the sum of cached_num_pages for all data_requests" do
      create(:data_request, data_request_area:, cached_num_pages: 5)
      create(:data_request, data_request_area:, cached_num_pages: 10)

      expect(decorated.cached_num_pages).to eq(15)
    end
  end

  describe "#date_requested" do
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

  describe "#request_dates" do
    context "with multiple data_requests with only a from date" do
      before do
        create(:data_request, data_request_area:, date_from: Date.new(2022, 8, 20))
        create(:data_request, data_request_area:, date_from: Date.new(2023, 7, 15))
      end

      it "returns string for all requests" do
        expect(decorated.request_dates).to eq "from 20/08/2022 to date\nfrom 15/07/2023 to date"
      end
    end

    context "with multiple data_requests with only a to date" do
      before do
        create(:data_request, data_request_area:, date_to: Date.new(2022, 12, 13))
        create(:data_request, data_request_area:, date_to: Date.new(2023, 11, 10))
      end

      it "returns concatenated string for all requests" do
        expect(decorated.request_dates).to eq "up to 13/12/2022\nup to 10/11/2023"
      end
    end

    context "with multiple data_requests with both from and to dates" do
      before do
        create(:data_request, data_request_area:, date_from: Date.new(2022, 12, 13), date_to: Date.new(2022, 12, 13))
        create(:data_request, data_request_area:, date_from: Date.new(2023, 12, 13), date_to: Date.new(2023, 12, 13))
      end

      it "returns concatenated string for all requests" do
        expect(decorated.request_dates).to eq "from 13/12/2022 to 13/12/2022\nfrom 13/12/2023 to 13/12/2023"
      end
    end

    context "with completed data_requests" do
      before do
        create(:data_request, data_request_area:, date_from: Date.new(2022, 12, 13), date_to: Date.new(2022, 12, 13))
        create(:data_request, :completed, data_request_area:, date_from: Date.new(2023, 12, 13), date_to: Date.new(2023, 12, 13))
      end

      it "only returns in progress data requests dates" do
        expect(decorated.request_dates).to eq "from 13/12/2022 to 13/12/2022"
      end
    end
  end

  describe "#request_document" do
    before do
      create :commissioning_document, data_request_area:
    end

    it "displays the current request document" do
      expect(decorated.request_document).to eq("Day 1 commissioning")
    end
  end

  describe "#data_request_area_status_tag" do
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

  describe "#next_chase_description" do
    before do
      allow(decorated).to receive(:next_chase_number).and_return(3)
      allow(decorated).to receive(:next_chase_date).and_return(Date.new(2025, 1, 31))
      allow(decorated).to receive(:next_chase_type).and_return(type)
    end

    context "when standard chase" do
      let(:type) { DataRequestChase::STANDARD_CHASE }

      it "returns expected string" do
        expect(decorated.next_chase_description).to eq "Chase 3 will be sent on 31 Jan 2025"
      end
    end

    context "when escalated chase" do
      let(:type) { DataRequestChase::ESCALATION_CHASE }

      it "returns expected string" do
        expect(decorated.next_chase_description).to eq "Chase 3 escalated will be sent on 31 Jan 2025"
      end
    end

    context "when overdue chase" do
      let(:type) { DataRequestChase::OVERDUE_CHASE }

      it "returns expected string" do
        expect(decorated.next_chase_description).to eq "Chase 3 overdue will be sent on 31 Jan 2025"
      end
    end
  end
end
