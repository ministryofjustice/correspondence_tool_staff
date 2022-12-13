require 'rails_helper'

describe DataRequestDecorator, type: :model do
  describe "#request_dates" do
    let(:decorated) { find_or_create(:data_request).decorate }

    context "only a from date" do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 8, 20)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "from 20/08/2022 to date"
      end
    end

    context "only a to date" do
      let(:decorated) { find_or_create(:data_request, date_to: Date.new(2022, 12, 13)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "up to 13/12/2022"
      end
    end

    context "both from and to dates" do
      let(:decorated) { find_or_create(:data_request, date_from: Date.new(2022, 12, 13), date_to: Date.new(2022, 12, 13)).decorate }

      it "returns expected string" do
        expect(decorated.request_dates).to eq "from 13/12/2022 to 13/12/2022"
      end
    end

    context "neither to or from dates" do
      it "returns an empty string" do
        expect(decorated.request_dates).to eq ""
      end
    end
  end
end
