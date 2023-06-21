# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  query            :jsonb            not null
#  num_results      :integer          default(0), not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#

require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe SearchQuery do
  describe "tree functions" do
    let(:root) { create :search_query, search_text: "root" }
    let!(:child) do
      create :search_query, :filter,
             parent_id: root.id,
             filter_case_type: %w[foi-standard]
    end
    let!(:child_2) do
      create :search_query, :filter,
             parent_id: root.id,
             filter_case_type: %w[foi-ir-compliance]
    end

    describe "root" do
      it "find the top-most ancestor" do
        expect(child.root).to eq root
      end
    end

    describe "ancestors" do
      context "with a child node" do
        it "returns an array of ancestors, root last" do
          expect(child.ancestors).to eq([root])
        end
      end

      context "with the root node" do
        it "returns and empty array" do
          expect(root.ancestors).to be_empty
        end
      end
    end

    describe ".descendents" do
      it "returns and array of descendents, oldest child first" do
        expect(root.descendants).to eq([child, child_2])
      end
    end
  end

  describe "self.filter_attributes" do
    it "returns all the filter attributes" do
      expect(described_class.filter_attributes).to match_array %i[
        common_exemption_ids
        exemption_ids
        external_deadline_from
        external_deadline_to
        internal_deadline_from
        internal_deadline_to
        planned_destruction_date_from
        planned_destruction_date_to
        filter_case_type
        filter_open_case_status
        filter_sensitivity
        filter_status
        filter_timeliness
        filter_high_profile
        filter_complaint_type
        filter_complaint_priority
        filter_complaint_subtype
        filter_caseworker
        filter_partial_case_flag
        filter_retention_state
        date_responded_from
        date_responded_to
        received_date_from
        received_date_to
      ]
    end
  end

  describe "self.find_or_create" do
    context "with search queries" do
      let(:user) { find_or_create(:disclosure_bmt_user) }

      let(:parent_search_query) do
        create(
          :search_query,
          user:,
          query_type: "search",
          search_text: "winnie-the-pooh",
        )
      end
      let(:existing_search_query) do
        create(
          :search_query,
          user:,
          query_type: "search",
          search_text: "winnie-the-pooh",
          parent_id: parent_search_query.id,
          filter_case_type: %w[foi-standard],
          filter_sensitivity: %w[trigger],
          external_deadline_from: Date.new(2018, 5, 20),
          external_deadline_to: Date.new(2018, 5, 30),
          internal_deadline_from: nil,
          internal_deadline_to: nil,
          filter_timeliness: %w[in-time],
          exemption_ids: [21],
          common_exemption_ids: [21],
          filter_status: %w[open],
          received_date_from: nil,
          received_date_to: nil,
          date_responded_from: nil,
          date_responded_to: nil,
          planned_destruction_date_from: nil,
          planned_destruction_date_to: nil,
        )
      end
      let(:query_params) do
        ActionController::Parameters.new(
          user_id: user.id.to_s,
          parent_id: parent_search_query.id.to_s,
          query_type: "search",
          filter_case_type: %w[foi-standard],
          filter_sensitivity: %w[trigger],
          external_deadline_from: Date.new(2018, 5, 20),
          external_deadline_to: Date.new(2018, 5, 30),
          filter_timeliness: %w[in-time],
          exemption_ids: [21],
          common_exemption_ids: [21],
          filter_status: %w[open],
        ).permit!
      end

      it "finds matching queries made today" do
        existing_search_query
        found_search_query = described_class.find_or_create(query_params)
        expect(found_search_query).to eq existing_search_query
      end

      it "creates a child to the parent if does not match an existing query" do
        parent_search_query
        expect {
          new_search_query = described_class.find_or_create(query_params)
          expect(new_search_query).to eq described_class.last
        }.to change(described_class, :count).by(1)
      end
    end

    context "with list queries" do
      let(:user) { find_or_create(:disclosure_bmt_user) }

      let(:parent_list_query) do
        create(
          :list_query,
          user:,
          query_type: "list",
          list_path: "/cases/open",
        )
      end
      let(:existing_list_query) do
        create(
          :list_query,
          user:,
          query_type: "list",
          list_path: "/cases/open",
          parent_id: parent_list_query.id,
          filter_case_type: %w[foi-standard],
          filter_sensitivity: %w[trigger],
          external_deadline_from: Date.new(2018, 5, 20),
          external_deadline_to: Date.new(2018, 5, 30),
          internal_deadline_from: nil,
          internal_deadline_to: nil,
          filter_timeliness: %w[in-time],
          exemption_ids: [21],
          common_exemption_ids: [21],
          filter_open_case_status: %w[unassigned],
          received_date_from: nil,
          received_date_to: nil,
          date_responded_from: nil,
          date_responded_to: nil,
          filter_status: [],
          planned_destruction_date_from: nil,
          planned_destruction_date_to: nil,
        )
      end
      let(:query_params) do
        ActionController::Parameters.new(
          user_id: user.id.to_s,
          parent_id: parent_list_query.id.to_s,
          query_type: "list",
          filter_case_type: %w[foi-standard],
          filter_sensitivity: %w[trigger],
          external_deadline_from: Date.new(2018, 5, 20),
          external_deadline_to: Date.new(2018, 5, 30),
          filter_timeliness: %w[in-time],
          exemption_ids: [21],
          common_exemption_ids: [21],
          filter_open_case_status: %w[unassigned],
        ).permit!
      end

      it "finds matching queries made today" do
        existing_list_query
        found_list_query = described_class.find_or_create(query_params)
        expect(found_list_query).to eq existing_list_query
      end
    end
  end

  describe "self.query_attributes" do
    it "returns all the query attributes" do
      expect(described_class.query_attributes).to match_array %i[
        search_text
        list_path
        common_exemption_ids
        exemption_ids
        external_deadline_from
        external_deadline_to
        internal_deadline_from
        internal_deadline_to
        planned_destruction_date_from
        planned_destruction_date_to
        filter_case_type
        filter_open_case_status
        filter_sensitivity
        filter_status
        filter_timeliness
        filter_high_profile
        filter_complaint_type
        filter_complaint_priority
        filter_complaint_subtype
        filter_caseworker
        filter_partial_case_flag
        filter_retention_state
        date_responded_from
        date_responded_to
        received_date_from
        received_date_to
      ]
    end
  end

  describe "#update_for_click" do
    context "when user clicks for the first time" do
      let(:search_query) { create :search_query }
      let(:position)     { 3 }

      it "records the click" do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 1
      end

      it "updates the highest position" do
        new_highest_position = 2
        search_query.update_for_click(new_highest_position)
        expect(search_query.highest_position).to eq new_highest_position
      end
    end

    context "when user clicks on higher option" do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 1 }

      it "records the click" do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it "updates the highest position" do
        search_query.update_for_click(position)
        search_query.reload
        expect(search_query.highest_position).to eq position
      end
    end

    context "when user clicks on a lower position" do
      let(:search_query) { create :search_query, :clicked }
      let(:position)     { 33 }

      it "records the click" do
        search_query.update_for_click(position)
        expect(search_query.num_clicks).to eq 2
      end

      it "does not update the highest position" do
        search_query.update_for_click(position)
        expect(search_query.highest_position).to eq 3
      end
    end
  end

  describe "#results" do
    before :all do
      @responding_team = find_or_create :foi_responding_team
      @sar_responder = find_or_create :sar_responder
      @setup = StandardSetup.new(only_cases: {
        std_draft_foi: {},
        std_draft_foi_late: {},
        trig_draft_foi: {},
        std_draft_irt: {},
        std_closed_foi: {},
        ico_foi_unassigned: {},
        ico_foi_awaiting_responder: { responding_team: @responding_team },
        ico_foi_accepted: { responding_team: @responding_team },
        ico_sar_unassigned: {},
        ico_sar_awaiting_responder: { responding_team: @responding_team },
        ico_sar_accepted: { responding_team: @sar_responder.responding_teams.first },
        ico_sar_pending_dacu: { responding_team: @responding_team },
      })
      Case::Base.update_all_indexes
    end

    after :all do
      DbHousekeeping.clean
    end

    let(:user) { find_or_create :disclosure_bmt_user }

    describe "results from using a filter" do
      it "returns the result of searching for search_text" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "std_draft_foi"
        expect(search_query.results).to eq [@setup.std_draft_foi,
                                            @setup.std_draft_foi_late,
                                            @setup.std_draft_irt]
      end

      it "returns the result of searching for search_text with newest case first" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "std_draft_foi"
        expect(search_query.results(nil, "search_result_order_by_newest_first"))
          .to eq [@setup.std_draft_foi,
                  @setup.std_draft_foi_late,
                  @setup.std_draft_irt]
      end

      it "returns the result of searching for search_text with oldest case first" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "std_draft"
        expect(search_query.results(nil, "search_result_order_by_oldest_first"))
          .to eq [@setup.std_draft_foi,
                  @setup.std_draft_irt,
                  @setup.std_draft_foi_late]
      end

      it "returns the result of filtering for sensitivity" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "draft",
                              filter_sensitivity: %w[trigger]
        expect(search_query.results).to eq [@setup.trig_draft_foi]
      end

      describe "filtering by type" do
        context "when filtering by FOI Internal review for timeliness" do
          it "returns the result of filtering for type" do
            search_query = create :search_query,
                                  user_id: user.id,
                                  search_text: "draft",
                                  filter_case_type: %w[foi-ir-timeliness]
            expect(search_query.results).to eq [@setup.std_draft_irt]
          end
        end

        context "when filtering by ICO" do
          context "with manager" do
            it "returns ICO appeals for both FOIs and SARs" do
              search_query = create :search_query,
                                    user_id: user.id,
                                    search_text: "ico",
                                    filter_case_type: %w[ico-appeal]
              expect(search_query.results).to eq [@setup.ico_foi_unassigned,
                                                  @setup.ico_foi_awaiting_responder,
                                                  @setup.ico_foi_accepted,
                                                  @setup.ico_sar_unassigned,
                                                  @setup.ico_sar_awaiting_responder,
                                                  @setup.ico_sar_accepted,
                                                  @setup.ico_sar_pending_dacu]
            end
          end

          context "when responder in a team that the ICO SARs are not assigned to" do
            it "doesnt show the ICO SAR" do
              search_query = create :search_query,
                                    user_id: @sar_responder.id,
                                    search_text: "ico",
                                    filter_case_type: %w[ico-appeal]
              expect(search_query.results).to eq [@setup.ico_foi_unassigned,
                                                  @setup.ico_foi_awaiting_responder,
                                                  @setup.ico_foi_accepted,
                                                  @setup.ico_sar_accepted]
            end
          end

          context "when responder in a team that the ICO SARs have been assigned to" do
            it "returns only those ico sars that are assigned to the responders team" do
              responder = @responding_team.users.first
              search_query = create :search_query,
                                    user_id: responder.id,
                                    search_text: "ico",
                                    filter_case_type: %w[ico-appeal]
              expect(search_query.results).to eq [@setup.ico_foi_unassigned,
                                                  @setup.ico_foi_awaiting_responder,
                                                  @setup.ico_foi_accepted,
                                                  @setup.ico_sar_awaiting_responder,
                                                  @setup.ico_sar_pending_dacu]
            end
          end

          context "when disclosure specialist" do
            it "returns ICO appeals for both FOIs and SARs" do
              disclosure_specialist = find_or_create :disclosure_specialist
              search_query = create :search_query,
                                    user_id: disclosure_specialist.id,
                                    search_text: "ico",
                                    filter_case_type: %w[ico-appeal]
              expect(search_query.results)
                .to eq [@setup.ico_foi_unassigned,
                        @setup.ico_foi_awaiting_responder,
                        @setup.ico_foi_accepted,
                        @setup.ico_sar_unassigned,
                        @setup.ico_sar_awaiting_responder,
                        @setup.ico_sar_accepted,
                        @setup.ico_sar_pending_dacu]
            end
          end

          context "when press officer" do
            it "doesnt show the ICO SAR" do
              press_officer = find_or_create :press_officer
              search_query = create :search_query,
                                    user_id: press_officer.id,
                                    search_text: "ico",
                                    filter_case_type: %w[ico-appeal]
              expect(search_query.results).to eq [@setup.ico_foi_unassigned,
                                                  @setup.ico_foi_awaiting_responder,
                                                  @setup.ico_foi_accepted]
            end
          end
        end
      end

      it "returns the result of filtering by status" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "std",
                              filter_status: %w[closed]
        expect(search_query.results).to eq [@setup.std_closed_foi]
      end

      it "returns the result of filtering by timeliness" do
        search_query = create :search_query,
                              user_id: user.id,
                              search_text: "draft",
                              filter_timeliness: %w[late]
        expect(search_query.results).to eq [@setup.std_draft_foi_late]
      end
    end

    context "when case listing" do
      it "uses the list of cases if provided" do
        cases_list = Case::Base.where(id: [@setup.std_draft_foi.id,
                                           @setup.std_draft_irt.id])

        search_query = create :search_query, :simple_list,
                              user_id: user.id,
                              filter_case_type: %w[foi-standard]
        expect(search_query.results(cases_list)).to eq [@setup.std_draft_foi]
      end
    end

    context "when no list of cases provided" do
      it "uses the list of cases if provided" do
        search_query = create :search_query, :simple_list,
                              user_id: user.id,
                              filter_case_type: %w[foi-standard]
        expect { search_query.results }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#params_without_filters" do
    it "returns all the filter attributes" do
      search_query = create :search_query

      expect(search_query.params_without_filters)
        .to eq({ "search_text" => "Winnie the Pooh",
                 "list_path" => nil })
    end
  end

  describe "#applied_filters" do
    it "includes case type filters" do
      search_query = create :search_query, filter_case_type: %w[foi-standard]
      expect(search_query.applied_filters).to eq [CaseFilter::CaseTypeFilter]
    end

    it "includes status filters" do
      search_query = create :search_query, filter_status: %w[closed]
      expect(search_query.applied_filters).to eq [CaseFilter::CaseStatusFilter]
    end

    it "includes open status filters" do
      search_query = create :search_query, filter_open_case_status: %w[unassigned]
      expect(search_query.applied_filters).to eq [CaseFilter::OpenCaseStatusFilter]
    end

    it "includes trigger flag filters" do
      search_query = create :search_query, filter_sensitivity: %w[trigger]
      expect(search_query.applied_filters).to eq [CaseFilter::CaseTriggerFlagFilter]
    end

    it "includes exemption filters" do
      search_query = create :search_query, exemption_ids: [2]
      expect(search_query.applied_filters).to eq [CaseFilter::ExemptionFilter]
    end

    it "includes external deadline filters" do
      search_query = create :search_query,
                            external_deadline_from: Time.zone.today,
                            external_deadline_to: Time.zone.today
      expect(search_query.applied_filters).to eq [CaseFilter::ExternalDeadlineFilter]
    end

    it "includes received date filters" do
      search_query = create :search_query,
                            received_date_from: Time.zone.today,
                            received_date_to: Time.zone.today
      expect(search_query.applied_filters).to eq [CaseFilter::ReceivedDateFilter]
    end

    it "includes date responded filters" do
      search_query = create :search_query,
                            date_responded_from: Time.zone.today,
                            date_responded_to: Time.zone.today
      expect(search_query.applied_filters).to eq [CaseFilter::DateRespondedFilter]
    end

    it "includes timeliness filters" do
      search_query = create :search_query, filter_timeliness: %w[in_time]
      expect(search_query.applied_filters).to eq [CaseFilter::TimelinessFilter]
    end

    it "includes retention state filter" do
      search_query = create :search_query, filter_retention_state: %w[review]
      expect(search_query.applied_filters).to eq [CaseFilter::CaseRetentionStateFilter]
    end

    it "includes retention deadline filter" do
      search_query = create :search_query, planned_destruction_date_from: Time.zone.today, planned_destruction_date_to: Time.zone.today
      expect(search_query.applied_filters).to eq [CaseFilter::CaseRetentionDeadlineFilter]
    end
  end

  describe "#available_filters" do
    context "when FOI/SAR/ICO case type related for London users" do
      it "Open cases tab" do
        search_query = create :search_query
        expect(search_query.available_filters(search_query.user, "all_cases").map(&:class)).to eq [
          CaseFilter::OpenCaseStatusFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::CaseTriggerFlagFilter,
          CaseFilter::TimelinessFilter,
          CaseFilter::ExternalDeadlineFilter,
          CaseFilter::InternalDeadlineFilter,
        ]
      end

      it "Closed cases tab" do
        search_query = create :search_query
        expect(search_query.available_filters(search_query.user, "closed").map(&:class)).to eq [
          CaseFilter::ReceivedDateFilter,
          CaseFilter::DateRespondedFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::ExemptionFilter,
        ]
      end

      it "My open tab" do
        search_query = create :search_query
        expect(search_query.available_filters(search_query.user, "my_cases").map(&:class)).to eq [
          CaseFilter::OpenCaseStatusFilter,
        ]
      end

      it "Search tab" do
        search_query = create :search_query
        expect(search_query.available_filters(search_query.user, "search_cases").map(&:class)).to eq [
          CaseFilter::CaseStatusFilter,
          CaseFilter::OpenCaseStatusFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::CaseTriggerFlagFilter,
          CaseFilter::TimelinessFilter,
          CaseFilter::ExternalDeadlineFilter,
          CaseFilter::ExemptionFilter,
        ]
      end
    end

    context "when Offender / Complaint case types related for Branston users" do
      let(:user) { find_or_create(:branston_user) }

      it "Open cases tab" do
        search_query = create :search_query
        expect(search_query.available_filters(user, "all_cases").map(&:class)).to eq [
          CaseFilter::OpenCaseStatusFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::TimelinessFilter,
          CaseFilter::ExternalDeadlineFilter,
          CaseFilter::CaseHighProfileFilter,
          CaseFilter::CaseComplaintTypeFilter,
          CaseFilter::CaseComplaintSubtypeFilter,
          CaseFilter::CaseComplaintPriorityFilter,
          CaseFilter::CaseworkerFilter,
        ]
      end

      it "Closed cases tab" do
        search_query = create :search_query
        expect(search_query.available_filters(user, "closed").map(&:class)).to eq [
          CaseFilter::ReceivedDateFilter,
          CaseFilter::DateRespondedFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::CaseHighProfileFilter,
          CaseFilter::CaseComplaintTypeFilter,
          CaseFilter::CaseComplaintSubtypeFilter,
          CaseFilter::CaseComplaintPriorityFilter,
          CaseFilter::CasePartialCaseFlagFilter,
        ]
      end

      it "My open tab" do
        search_query = create :search_query
        expect(search_query.available_filters(user, "my_cases").map(&:class)).to eq [
          CaseFilter::OpenCaseStatusFilter,
          CaseFilter::CaseComplaintTypeFilter,
          CaseFilter::CaseComplaintSubtypeFilter,
          CaseFilter::CaseComplaintPriorityFilter,
        ]
      end

      it "Pending removal tab" do
        search_query = create :search_query
        expect(
          search_query.available_filters(user, "retention_pending_removal").map(&:class),
        ).to eq [
          CaseFilter::CaseRetentionDeadlineFilter,
          CaseFilter::CaseRetentionStateFilter,
        ]
      end

      it "Ready for removal tab" do
        search_query = create :search_query
        expect(
          search_query.available_filters(user, "retention_ready_for_removal").map(&:class),
        ).to eq [CaseFilter::CaseRetentionDeadlineFilter]
      end

      it "Search tab" do
        search_query = create :search_query
        expect(search_query.available_filters(user, "search_cases").map(&:class)).to eq [
          CaseFilter::CaseStatusFilter,
          CaseFilter::OpenCaseStatusFilter,
          CaseFilter::CaseTypeFilter,
          CaseFilter::TimelinessFilter,
          CaseFilter::ExternalDeadlineFilter,
          CaseFilter::CaseHighProfileFilter,
          CaseFilter::CaseComplaintTypeFilter,
          CaseFilter::CaseComplaintSubtypeFilter,
          CaseFilter::CaseComplaintPriorityFilter,
          CaseFilter::CasePartialCaseFlagFilter,
        ]
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
