require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::ReceivedDateFilter do
  let(:user) { find_or_create :disclosure_specialist_bmt }
  let(:kase_1) { @kase_1 }
  let(:kase_2) { @kase_2 }

  before(:all) do
    Timecop.freeze(Time.zone.local(2018, 4, 26, 14, 57, 0)) do
      @kase_1 = create :case, received_date: 30.business_days.ago
      @kase_2 = create :case, received_date: 25.business_days.ago
      @kase_3 = create :case, received_date: 100.business_days.ago
    end
  end

  after(:all) { DbHousekeeping.clean }

  describe "#applied?" do
    subject { filter }

    let(:filter) { described_class.new(search_query, :user, Case::Base.all) }

    context "when no received_date present" do
      let(:search_query)      { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when both from and to received_date present" do
      let(:search_query)      do
        create :search_query,
               received_date_from: Time.zone.today,
               received_date_to: Time.zone.today
      end

      it { is_expected.to be_applied }
    end

    context "when only received_date_from present" do
      let(:search_query) do
        create :search_query,
               received_date_from: Time.zone.today
      end

      it { is_expected.not_to be_applied }
    end

    context "when only received_date_to present" do
      let(:search_query) do
        create :search_query,
               received_date_to: Time.zone.today
      end

      it { is_expected.not_to be_applied }
    end
  end

  describe "#call" do
    let(:arel)    { Case::Base.all }
    let(:filter)  { described_class.new(search_query, :user, arel) }

    context "when no cases with received date in date range" do
      let(:search_query) do
        create :search_query,
               received_date_from: Date.new(2017, 12, 4),
               received_date_to: Date.new(2017, 12, 25)
      end

      it "returns an empty collection" do
        Timecop.freeze(Time.zone.local(2018, 4, 26, 14, 57, 0)) do
          expect(filter.call).to eq []
        end
      end
    end

    context "when case with received_date within date rang" do
      let(:search_query) do
        create :search_query,
               received_date_from: Date.new(2018, 3, 1),
               received_date_to: Date.new(2018, 4, 25)
      end

      it "returns only cases within date range" do
        Timecop.freeze(Time.zone.local(2018, 4, 26, 14, 57, 0)) do
          expect(filter.call).to match_array [kase_1, kase_2]
        end
      end
    end
  end

  describe "#crumbs" do
    let(:arel)          { Case::Base.all }
    let(:filter)        { described_class.new(search_query, user, arel) }

    context "when no received_date from or to selected" do
      let(:search_query) do
        create :search_query,
               received_date_from: nil,
               received_date_to: nil
      end

      it "returns no crumbs" do
        expect(filter.crumbs).to be_empty
      end
    end

    context "when from and to date selected" do
      let(:search_query) do
        create :search_query,
               received_date_from: Date.new(2017, 12, 4),
               received_date_to: Date.new(2017, 12, 25)
      end

      it "returns a single crumb" do
        expect(filter.crumbs).to have(1).items
      end

      it "uses the from and to dates in the crumb text" do
        expect(filter.crumbs[0].first).to eq "Received date 4 Dec 2017 - 25 Dec 2017"
      end

      describe "params that will be submitted when clicking on the crumb" do
        it {
          expect(filter.crumbs[0].second).to eq "received_date_from" => "",
                                                "received_date_to" => "",
                                                "parent_id" => search_query.id
        }
      end
    end
  end

  describe ".process_params!" do
    describe "when processing received_date_from" do
      it "converts dates from govuk date fields" do
        params = {
          received_date_from_yyyy: "2018",
          received_date_from_mm: "05",
          received_date_from_dd: "27",
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:received_date_from]).to eq Date.new(2018, 5, 27)
      end

      it "clears out an empty date" do
        params = { received_date_from: "" }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:received_date_from]).to be_nil
      end
    end

    describe "when processing received_date_to" do
      it "converts dates from govuk date fields" do
        params = {
          received_date_to_yyyy: "2018",
          received_date_to_mm: "05",
          received_date_to_dd: "27",
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:received_date_to]).to eq Date.new(2018, 5, 27)
      end

      it "clears out an empty date" do
        params = { received_date_to: "" }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:received_date_to]).to be nil
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
