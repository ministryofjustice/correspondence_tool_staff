require "rails_helper"

describe DataRequestAreaDecorator, type: :model do

  describe "#location" do
    let(:data_request_area) { create(:data_request_area) }

    context "without linked organisation" do
      let(:decorated) { data_request_area.decorate }

      it "uses location string" do
        expect(decorated.location).to eq data_request_area.location
      end
    end

    context "with linked organisation" do
      let(:contact) { create(:contact) }
      let(:decorated) { data_request_area.decorate }

      before do
        data_request_area.update!(contact:)
      end

      it "uses name of organisation" do
        expect(decorated.location).to eq contact.name
      end
    end
  end

  describe "#date_completed" do
    
  end

  describe "#date_requested" do

  end

  describe "#cached_num_pages" do

  end

  describe "#num_of_requests" do

  end

  describe "#data_request_status_tag" do

  end

  describe "#request_document" do

  end
end
