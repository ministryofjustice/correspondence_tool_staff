require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFilter::AcknowledgementDeadlineFilter do
  let(:branston_user) { find_or_create :branston_user }
  let(:disclosure_user) { find_or_create :disclosure_specialist_bmt }

  before(:all) do
    @complaint_1 = create :offender_sar_complaint,
                          complaint_type: "standard_complaint",
                          received_date: Date.new(2026, 1, 5)
    @complaint_1.update_column(:properties,
                               @complaint_1.properties.merge("acknowledgement_deadline" => "2026-01-19"))

    @complaint_2 = create :offender_sar_complaint,
                          complaint_type: "standard_complaint",
                          received_date: Date.new(2026, 2, 2)
    @complaint_2.update_column(:properties,
                               @complaint_2.properties.merge("acknowledgement_deadline" => "2026-02-16"))
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "#applied?" do
    subject { filter }

    let(:filter) { described_class.new(search_query, branston_user, Case::Base.all) }

    context "when no acknowledgement_deadline present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when both from and to present" do
      let(:search_query) do
        create :search_query,
               acknowledgement_deadline_from: Date.new(2026, 1, 19),
               acknowledgement_deadline_to: Date.new(2026, 1, 19)
      end

      it { is_expected.to be_applied }
    end

    context "when only acknowledgement_deadline_from present" do
      let(:search_query) do
        create :search_query, acknowledgement_deadline_from: Date.new(2026, 1, 19)
      end

      it { is_expected.not_to be_applied }
    end

    context "when only acknowledgement_deadline_to present" do
      let(:search_query) do
        create :search_query, acknowledgement_deadline_to: Date.new(2026, 1, 19)
      end

      it { is_expected.not_to be_applied }
    end
  end

  describe "#call" do
    let(:arel)   { Case::Base.all }
    let(:filter) { described_class.new(search_query, branston_user, arel) }

    context "when no cases fall within the date range" do
      let(:search_query) do
        create :search_query,
               acknowledgement_deadline_from: Date.new(2026, 3, 1),
               acknowledgement_deadline_to: Date.new(2026, 3, 31)
      end

      it "returns an empty collection" do
        expect(filter.call).not_to include(@complaint_1, @complaint_2)
      end
    end

    context "when cases fall within the date range" do
      let(:search_query) do
        create :search_query,
               acknowledgement_deadline_from: Date.new(2026, 1, 1),
               acknowledgement_deadline_to: Date.new(2026, 1, 31)
      end

      it "returns only cases within the date range" do
        expect(filter.call).to include(@complaint_1)
        expect(filter.call).not_to include(@complaint_2)
      end
    end
  end

  describe "#is_permitted_for_user?" do
    let(:filter) { described_class.new(create(:search_query), user, Case::Base.all) }

    context "when user has OFFENDER_SAR_COMPLAINT correspondence type" do
      let(:user) { branston_user }

      it "returns true" do
        expect(filter.is_permitted_for_user?).to be true
      end
    end

    context "when user does not have OFFENDER_SAR_COMPLAINT correspondence type" do
      let(:user) { disclosure_user }

      it "returns false" do
        expect(filter.is_permitted_for_user?).to be false
      end
    end
  end

  describe "#crumbs" do
    let(:arel)   { Case::Base.all }
    let(:filter) { described_class.new(search_query, branston_user, arel) }

    context "when no dates selected" do
      let(:search_query) do
        create :search_query,
               acknowledgement_deadline_from: nil,
               acknowledgement_deadline_to: nil
      end

      it "returns no crumbs" do
        expect(filter.crumbs).to be_empty
      end
    end

    context "when from and to dates selected" do
      let(:search_query) do
        create :search_query,
               acknowledgement_deadline_from: Date.new(2026, 1, 5),
               acknowledgement_deadline_to: Date.new(2026, 1, 19)
      end

      it "returns a single crumb" do
        expect(filter.crumbs).to have(1).items
      end

      it "includes the dates in the crumb text" do
        expect(filter.crumbs[0].first).to eq "Acknowledgement deadline 5 Jan 2026 - 19 Jan 2026"
      end

      it "resets the filter when the crumb is clicked" do
        expect(filter.crumbs[0].second).to eq(
          "acknowledgement_deadline_from" => "",
          "acknowledgement_deadline_to" => "",
          "parent_id" => search_query.id,
        )
      end
    end
  end

  describe "#process_params!" do
    context "when processing acknowledgement_deadline_from" do
      it "converts govuk date components to a date" do
        params = {
          acknowledgement_deadline_from_yyyy: "2026",
          acknowledgement_deadline_from_mm: "01",
          acknowledgement_deadline_from_dd: "05",
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:acknowledgement_deadline_from]).to eq Date.new(2026, 1, 5)
      end

      it "clears an empty date" do
        params = { acknowledgement_deadline_from: "" }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:acknowledgement_deadline_from]).to be_nil
      end
    end

    context "when processing acknowledgement_deadline_to" do
      it "converts govuk date components to a date" do
        params = {
          acknowledgement_deadline_to_yyyy: "2026",
          acknowledgement_deadline_to_mm: "01",
          acknowledgement_deadline_to_dd: "19",
        }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:acknowledgement_deadline_to]).to eq Date.new(2026, 1, 19)
      end

      it "clears an empty date" do
        params = { acknowledgement_deadline_to: "" }.with_indifferent_access
        described_class.process_params!(params)
        expect(params[:acknowledgement_deadline_to]).to be_nil
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
