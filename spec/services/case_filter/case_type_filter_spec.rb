require "rails_helper"

describe CaseFilter::CaseTypeFilter do
  let(:user) { find_or_create :disclosure_specialist_bmt }
  let(:case_type_filter) { described_class.new search_query, user, Case::Base }

  before :all do
    DbHousekeeping.clean
    @setup = StandardSetup.new(only_cases: %i[
      sar_noff_unassigned
      std_unassigned_foi
      trig_unassigned_foi
      std_unassigned_irc
      std_unassigned_irt
      ico_foi_unassigned
      ico_sar_unassigned
      ot_ico_foi_noff_unassigned
      ot_ico_sar_noff_unassigned
    ])

    @offender_sar = create :offender_sar_case

    @sar_ir_timeliness = create :sar_internal_review, sar_ir_subtype: "timeliness"
    @sar_ir_compliance = create :sar_internal_review, sar_ir_subtype: "compliance"
  end

  after(:all) { DbHousekeeping.clean }

  describe ".available_case_types" do
    subject    { case_type_filter.available_choices.values[0] }

    let(:user) { find_or_create :disclosure_bmt_user }
    let(:search_query) { create :search_query }

    it { is_expected.to include "foi-standard"      => "FOI - Standard" }
    it { is_expected.to include "foi-ir-compliance" => "FOI - Internal review for compliance" }
    it { is_expected.to include "foi-ir-timeliness" => "FOI - Internal review for timeliness" }
    it { is_expected.to include "sar-non-offender"  => "SAR - Non-offender" }
    it { is_expected.to include "sar-ir-compliance" => "SAR - Internal review for compliance" }
    it { is_expected.to include "sar-ir-timeliness" => "SAR - Internal review for timeliness" }
    it { is_expected.to include "ico-appeal"        => "ICO appeals" }
    it { is_expected.to include "overturned-ico"    => "ICO overturned" }

    context "with user who is assigned to a team that only handles FOIs" do
      subject { case_type_filter.available_choices.values[0] }

      let(:foi)             { find_or_create(:foi_correspondence_type) }
      let(:responding_team) { create(:business_unit, correspondence_types: [foi]) }
      let(:user)            { create(:user, responding_teams: [responding_team]) }

      it { is_expected.to include "foi-standard" => "FOI - Standard" }
      it { is_expected.to include "foi-ir-compliance" => "FOI - Internal review for compliance" }
      it { is_expected.to include "foi-ir-timeliness" => "FOI - Internal review for timeliness" }
      it { is_expected.to include "overturned-ico" => "ICO overturned" }
      it { is_expected.not_to include "sar-non-offender" => "SAR - Non-offender" }
      it { is_expected.not_to include "ico-appeal" => "ICO appeals" }
    end
  end

  describe "#applied?" do
    subject { case_type_filter }

    context "when filter_case_type and filter_sensitivity not present" do
      let(:search_query)      { create :search_query }

      it { is_expected.not_to be_applied }
    end

    context "and filter_case_type present" do
      let(:search_query)      do
        create :search_query,
               filter_case_type: %w[foi-standard]
      end

      it { is_expected.to be_applied }
    end
  end

  describe "#call" do
    describe "filtering for standard FOI cases" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[foi-standard]
      end

      it "returns the correct list of cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.trig_unassigned_foi,
          @setup.std_unassigned_foi,
          @setup.ico_foi_unassigned.original_case,
          @setup.ot_ico_foi_noff_unassigned.original_case,
        ]
      end
    end

    describe "filtering for internal review of FOI cases for compliance" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[foi-ir-compliance]
      end

      it "returns the correct list of cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.std_unassigned_irc,
        ]
      end
    end

    describe "filtering for internal review of FOI cases for timeliness" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[foi-ir-timeliness]
      end

      it "returns the correct list of cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.std_unassigned_irt,
        ]
      end
    end

    describe "filtering for SAR cases" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[sar-non-offender]
      end

      it "returns the correct list of cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.sar_noff_unassigned,
          @setup.ico_sar_unassigned.original_case,
          @setup.ot_ico_sar_noff_unassigned.original_case,
          @sar_ir_timeliness.original_case,
          @sar_ir_compliance.original_case,
        ]
      end
    end

    describe "filtering SAR IR timeliness" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[sar-ir-timeliness]
      end

      it "returns SAR Internal review timeliness cases" do
        results = case_type_filter.call
        expect(results).to match_array [@sar_ir_timeliness]
        expect(results).not_to include @sar_ir_compliance
      end
    end

    describe "filtering SAR IR compliance" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[sar-ir-compliance]
      end

      it "returns SAR Internal review compliance cases" do
        results = case_type_filter.call
        expect(results).to match_array [@sar_ir_compliance]
        expect(results).not_to include @sar_ir_timeliness
      end
    end

    describe "filter SAR IR both timeliness and compliance" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[sar-ir-timeliness
                                    sar-ir-compliance]
      end

      it "returns both SAR Internal review compliance, and timeliness cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @sar_ir_timeliness,
          @sar_ir_compliance,
        ]
      end
    end

    describe "filtering for ICO cases" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[ico-appeal]
      end

      it "returns ICO FOI and ICO SAR cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.ico_foi_unassigned,
          @setup.ico_sar_unassigned,
          @setup.ot_ico_foi_noff_unassigned.original_ico_appeal,
          @setup.ot_ico_sar_noff_unassigned.original_ico_appeal,
        ]
      end
    end

    describe "filtering for Overturned ICO cases" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[overturned-ico]
      end

      it "returns Overturned FOI and Overturned SAR cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @setup.ot_ico_foi_noff_unassigned,
          @setup.ot_ico_sar_noff_unassigned,
        ]
      end
    end

    describe "filtering for Offender SAR cases" do
      let(:search_query) do
        create :search_query,
               filter_case_type: %w[offender-sar]
      end

      it "returns Overturned FOI and Overturned SAR cases" do
        results = case_type_filter.call
        expect(results).to match_array [
          @offender_sar,
        ]
      end
    end
  end

  describe "#crumbs" do
    context "when no filters selected" do
      let(:search_query) do
        create :search_query,
               filter_case_type: [],
               filter_sensitivity: []
      end

      it "returns no crumbs" do
        expect(case_type_filter.crumbs).to be_empty
      end
    end

    context "when filtering for cases based on type" do
      context "and filtering for standard FOI cases" do
        let(:search_query) do
          create :search_query,
                 filter_case_type: %w[foi-standard]
        end

        it "returns 1 crumb" do
          expect(case_type_filter.crumbs).to have(1).item
        end

        it 'uses "FOI - Standard" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq "FOI - Standard"
        end

        describe "params that will be submitted when clicking on the crumb" do
          subject { case_type_filter.crumbs[0].second }

          it {
            expect(subject).to eq "filter_case_type" => [""],
                                  "parent_id" => search_query.id
          }
        end
      end

      context "and filtering for internal review of FOI cases for compliance" do
        let(:search_query) do
          create :search_query,
                 filter_case_type: %w[foi-ir-compliance]
        end

        it 'uses "FOI - IR Compliance" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq "FOI - Internal review for compliance"
        end
      end

      context "and filtering for internal review of FOI cases for timeliness" do
        let(:search_query) do
          create :search_query,
                 filter_case_type: %w[foi-ir-timeliness]
        end

        it 'uses "FOI - IR Timeliness" for the crumb text' do
          expect(case_type_filter.crumbs[0].first).to eq "FOI - Internal review for timeliness"
        end
      end
    end
  end

  describe ".process_params!" do
    it "processes filter_case_type, sorting and removing blanks" do
      params = { filter_case_type: [
        "",
        "foi-standard",
        "foi-ir-compliance",
        "foi-ir-timeliness",
      ] }
      described_class.process_params!(params)
      expect(params).to eq filter_case_type: %w[
        foi-ir-compliance
        foi-ir-timeliness
        foi-standard
      ]
    end
  end
end
