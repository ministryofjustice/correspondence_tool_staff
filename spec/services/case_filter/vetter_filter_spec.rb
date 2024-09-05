require "rails_helper"

describe CaseFilter::VetterFilter do
  let(:user) { responding_team.responders.first }
  let(:responding_team) { find_or_create :team_branston }
  let!(:unassigned_vetting_case) { create :offender_sar_case, :ready_for_vetting }
  let!(:assigned_vetting_case) { create :offender_sar_case, :vetting_in_progress, responding_team: }
  let(:vetter_filter) { described_class.new search_query, user, Case::Base }

  describe ".available_vetter_filter" do
    subject { vetter_filter.available_choices.values[0] }

    let(:search_query) { create :search_query }

    it { is_expected.to include "0" => I18n.t("filters.filter_vetter.not_assigned") }
    it { is_expected.to include user.id.to_s => user.full_name }
  end

  describe "#applied?" do
    subject { vetter_filter }

    context "when vetter_filter not present" do
      let(:search_query) { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "when vetter_filter present" do
      let(:search_query) { create :search_query, filter_vetter: %w[0] }

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for unassigned cases" do
      let(:search_query) { create :search_query, filter_vetter: %w[0] }

      it "returns the unassigned vetting case " do
        results = vetter_filter.call
        expect(results).to match_array [unassigned_vetting_case]
      end
    end

    describe "filtering for assigned cases" do
      let(:search_query) { create :search_query, filter_vetter: [user.id.to_s] }

      it "returns the correct list of cases" do
        results = vetter_filter.call
        expect(results).to match_array [assigned_vetting_case]
      end
    end

    describe "filtering for all the vetting cases" do
      let(:search_query) do
        create :search_query,
               filter_vetter: ["0", user.id.to_s]
      end

      it "returns the correct list of cases" do
        results = vetter_filter.call
        expect(results).to match_array [unassigned_vetting_case, assigned_vetting_case]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_vetter: []
      end

      it "returns no crumbs" do
        expect(vetter_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases" do
      context "and filtering for unassigned cases" do
        let(:search_query) do
          create :search_query,
                 filter_vetter: %w[0]
        end

        it "returns 1 crumb" do
          expect(vetter_filter.crumbs).to have(1).item
        end

        it "uses for not assigned yet as the crumb text" do
          expect(vetter_filter.crumbs[0].first).to eq I18n.t("filters.filter_vetter.not_assigned")
        end

        describe "params that will be submitted when clicking on the crumb" do
          it {
            expect(vetter_filter.crumbs[0].second).to eq "filter_vetter" => [""],
                                                         "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for more than one type" do
        let(:search_query) do
          create :search_query,
                 filter_vetter: ["0", user.id.to_s]
        end

        it "Display right content for the crumb text" do
          expect(vetter_filter.crumbs[0].first).to eq "#{I18n.t('filters.filter_vetter.not_assigned')} + 1 more"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_vetter, sorting and removing blanks" do
      params = { filter_vetter: [
        "",
        "test",
        "abc",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_vetter: %w[
        abc
        test
      ]
    end
  end
end
