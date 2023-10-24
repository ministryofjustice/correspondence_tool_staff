require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseSearchService do
  let(:user) { create :manager }

  describe "#call" do
    before(:all) do
      @setup = StandardSetup.new(only_cases: %i[
        std_draft_foi
        trig_closed_foi
        std_unassigned_irc
        std_unassigned_irt
      ])
      Case::Base.update_all_indexes
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    let(:service) do
      described_class.new(user:,
                          query_type: :search,
                          query_params: params)
    end
    let(:params) do
      ActionController::Parameters.new(
        search_text: specific_query,
      ).permit!
    end

    context "with invalid date params" do
      let(:params) do
        ActionController::Parameters.new(
          external_deadline_from_dd: "31",
          external_deadline_from_mm: "2",
          external_deadline_from_yyyy: "2018",
          external_deadline_to_dd: "15",
          external_deadline_to_mm: "3",
          external_deadline_to_yyyy: "2018",
        ).permit!
      end

      it "does not raise" do
        expect {
          described_class.new(user:,
                              query_type: :search,
                              query_params: params)
        }.not_to raise_error
      end

      it "sets the error message" do
        service = described_class.new(user:,
                                      query_type: :search,
                                      query_params: params)
        service.call
        expect(service.error?).to be true
        expect(service.error_message).to eq "Invalid date"
      end
    end

    context "with use of the policy scope" do
      let(:specific_query) { "my scoped query" }

      it "uses the for_view_only policy scope" do
        expect(Case::BasePolicy::Scope).to receive(:new).with(user, Case::Base.all).and_call_original
        expect_any_instance_of(Case::BasePolicy::Scope) # rubocop:disable RSpec/AnyInstance
          .to receive(:resolve).and_call_original
        service.call
      end
    end

    context "when filtering on search results" do
      context "and performing fresh search (with no existing search)" do
        let(:specific_query) { "something" }

        it "sets search_query type to search" do
          service.call
          search_query = SearchQuery.last
          expect(search_query.query_type).to eq "search"
        end

        context "and blank query" do
          let(:specific_query) { "  " }

          it "errors" do
            service.call
            expect(service.error?).to be true
          end

          it "populates the error message" do
            service.call
            expect(service.error_message).to eq "Specify what you want to search for"
          end

          it "does not record a search_query record" do
            expect(SearchQuery.count).to eq 0
          end
        end

        context "and no results" do
          let(:specific_query) { "query resulting in no hits" }

          it "records a search_query record" do
            service.call
            expect(SearchQuery.count).to eq 1
            sq = SearchQuery.first
            expect(sq.search_text).to eq specific_query
            expect(sq.num_results).to eq 0
          end
        end

        context "with results" do
          context "and search by number" do
            let(:specific_query) { @setup.std_draft_foi.number }

            it "finds a case by number" do
              service.call
              expect(service.result_set).to eq [@setup.std_draft_foi]
            end
          end

          context "and search by text" do
            context "and no leading or trailing whitespace" do
              let(:specific_query) { "std_draft_foi" }

              it "finds a case by text" do
                service.call
                expect(service.result_set).to eq [@setup.std_draft_foi]
              end

              it "records a search_query record" do
                service.call
                expect(SearchQuery.count).to eq 1
                sq = SearchQuery.first
                expect(sq.search_text).to eq specific_query
                expect(sq.num_results).to eq 1
              end
            end

            context "and leading and trailing whitespace" do
              let(:specific_query) { "   std_draft_foi  " }

              it "ignores leading and trailing whitespace" do
                service.call
                expect(service.result_set).to eq [@setup.std_draft_foi]
              end

              it "records a search_query record" do
                service.call
                expect(SearchQuery.count).to eq 1
                sq = SearchQuery.first
                expect(sq.search_text).to eq specific_query.strip
                expect(sq.num_results).to eq 1
              end
            end
          end
        end
      end

      context "and applying filter on search results" do
        let!(:parent_search_query) { create(:search_query, search_text:, user_id: user.id) }
        let(:filter_case_type)           { ["", "foi-standard"] }
        let(:filter_sensitivity)         { [""] }
        let(:external_deadline_from)     { 0.working.days.from_now.to_date }
        let(:external_deadline_to)       { 10.working.days.from_now.to_date }

        let(:params) do
          ActionController::Parameters.new(
            parent_id: parent_search_query.id,
            filter_case_type:,
            filter_sensitivity:,
            external_deadline_from_dd: external_deadline_from&.day.to_s,
            external_deadline_from_mm: external_deadline_from&.month.to_s,
            external_deadline_from_yyyy: external_deadline_from&.year.to_s,
            external_deadline_to_dd: external_deadline_to&.day.to_s,
            external_deadline_to_mm: external_deadline_to&.month.to_s,
            external_deadline_to_yyyy: external_deadline_to&.year.to_s,
          ).permit!
        end
        let(:search_text) { "compliance" }

        context "and first filter applied by user" do
          it "creates a new search query" do
            expect {
              service.call
            }.to change(SearchQuery, :count).by(1)
          end

          describe "created search query" do
            subject { SearchQuery.last }

            before { service.call }

            it { is_expected.to have_attributes query_type: "search" }
            it { is_expected.to have_attributes user_id: user.id }
            it { is_expected.to have_attributes search_text: "compliance" }
            it { is_expected.to have_attributes parent_id: parent_search_query.id }
            it { is_expected.to have_attributes filter_case_type: filter_case_type.grep_v("") }
            it { is_expected.to have_attributes filter_sensitivity: filter_sensitivity.grep_v("") }
            it { is_expected.to have_attributes external_deadline_from: }
            it { is_expected.to have_attributes external_deadline_to: }
          end
        end

        context "and user has another filter applied" do
          let!(:parent_search_query) do
            create :search_query,
                   user_id: user.id,
                   search_text:,
                   filter_status: %w[open]
          end

          it "creates a new search query with the existing filter" do
            expect {
              service.call
            }.to change(SearchQuery, :count).by(1)
          end

          describe "created search query" do
            subject { SearchQuery.last }

            before { service.call }

            it { is_expected.to have_attributes query_type: "search" }
            it { is_expected.to have_attributes user_id: user.id }
            it { is_expected.to have_attributes search_text: "compliance" }
            it { is_expected.to have_attributes parent_id: parent_search_query.id }
            it { is_expected.to have_attributes filter_status: %w[open] }
            it { is_expected.to have_attributes filter_case_type: filter_case_type.grep_v("") }
            it { is_expected.to have_attributes filter_sensitivity: filter_sensitivity.grep_v("") }
            it { is_expected.to have_attributes external_deadline_from: }
            it { is_expected.to have_attributes external_deadline_to: }
          end
        end

        context "and search and filters have already been used by this user" do
          it "retrieves the existing SearchQuery" do
            existing_search_query = create :search_query,
                                           search_text:,
                                           list_path: nil,
                                           user:,
                                           parent_id: parent_search_query.id,
                                           filter_case_type: %w[foi-standard],
                                           external_deadline_from:,
                                           external_deadline_to:,
                                           planned_destruction_date_from: nil,
                                           planned_destruction_date_to: nil,
                                           internal_deadline_from: nil,
                                           internal_deadline_to: nil,
                                           received_date_from: nil,
                                           received_date_to: nil,
                                           date_responded_from: nil,
                                           date_responded_to: nil,
                                           filter_status: [],
                                           filter_sensitivity: [],
                                           filter_timeliness: [],
                                           exemption_ids: [],
                                           common_exemption_ids: []

            service.call
            expect(service.query).to eq existing_search_query
          end
        end

        it "performs the search/filter using the SearchQuery" do
          expected_results = instance_double("expected results", size: 1)
          search_query = create(:search_query)
          allow(search_query).to receive(:results).and_return(expected_results)
          allow(SearchQuery).to receive(:new).and_return(search_query)
          service.call
          expect(service.result_set).to eq expected_results
        end

        describe "search results" do
          let(:filter_case_type)       { [] }
          let(:filter_sensitivity)     { [] }
          let(:external_deadline_from) { nil }
          let(:external_deadline_to)   { nil }

          context "and search text" do
            let(:search_text) { "closed" }

            it "is used" do
              service.call
              expect(service.result_set)
                .to match_array [@setup.trig_closed_foi]
            end
          end

          context "and filter for sensitivity" do
            let(:search_text)        { "foi" }
            let(:filter_sensitivity) { %w[trigger] }

            it "is used" do
              service.call
              expect(service.result_set)
                .to match_array [@setup.trig_closed_foi]
            end
          end

          context "and filter for case type" do
            let(:search_text)        { "foi" }
            let(:filter_case_type)   { %w[foi-standard] }

            it "is used" do
              service.call
              expect(service.result_set)
                .to match_array [
                  @setup.std_draft_foi,
                  @setup.trig_closed_foi,
                ]
            end
          end

          context "and filter for external deadline" do
            let(:search_text)            { "foi" }
            let(:external_deadline_from) { 0.working.days.from_now.to_date }
            let(:external_deadline_to)   { 10.working.days.from_now.to_date }

            it "is used" do
              @setup.std_draft_foi.update!(external_deadline: 2.working.days.from_now)
              service.call
              expect(service.result_set)
                .to match_array [
                  @setup.std_draft_foi,
                ]
            end
          end
        end

        context "and parent id does not exist in database" do
          it "raises" do
            parent_search_query.destroy!
            expect {
              service.call
            }.to raise_error ActiveRecord::RecordNotFound,
                             /Couldn't find SearchQuery with 'id'=\d+/
          end
        end

        context "and different filter sensitivites exist already in the database" do
          let(:search_text)        { "case" }
          let(:filter_case_type)   { %w[foi-standard] }
          let(:filter_sensitivity) { %w[trigger non-trigger] }
          let(:params) do
            ActionController::Parameters.new(
              search_text: "case",
              filter_sensitivity: %w[trigger],
            ).permit!
          end

          it "creates a new record" do
            create :search_query,
                   user_id: user.id,
                   search_text: "case",
                   filter_sensitivity: %w[trigger non-trigger]

            expect {
              service.call
            }.to change(SearchQuery, :count).by(1)
          end
        end
      end
    end

    context "when filtering on list results" do
      let!(:parent_search_query)   { create :search_query, :simple_list }
      let(:service)                do
        described_class.new(user:,
                            query_type: :list,
                            query_params: params)
      end
      let(:filter_case_type)       { ["", "foi-standard"] }
      let(:filter_sensitivity)     { [""] }
      let(:full_list_of_cases)     { Case::Base.all }
      let(:params) do
        ActionController::Parameters.new(
          parent_id: parent_search_query.id,
          filter_case_type:,
          filter_sensitivity:,
        ).permit!
      end

      context "and first_filter applied by user" do
        it "creates a new search query" do
          expect {
            service.call(full_list_of_cases)
          }.to change(SearchQuery, :count).by(1)
          expect(SearchQuery.last.parent).to eq parent_search_query
        end
      end

      describe "created search query" do
        subject { SearchQuery.last }

        before { service.call(full_list_of_cases) }

        it { is_expected.to have_attributes query_type: "list" }
        it { is_expected.to have_attributes user_id: user.id }
        it { is_expected.to have_attributes search_text: nil }
        it { is_expected.to have_attributes list_path: parent_search_query.list_path }
        it { is_expected.to have_attributes parent_id: parent_search_query.id }
        it { is_expected.to have_attributes filter_case_type: filter_case_type.grep_v("") }
        it { is_expected.to have_attributes filter_sensitivity: filter_sensitivity.grep_v("") }
      end

      context "and user has another filter applied" do
        let(:params)    do
          ActionController::Parameters.new(
            parent_id: child_search_query.id,
            filter_case_type:,
            filter_sensitivity:,
          ).permit!
        end
        let!(:child_search_query) do
          create :search_query,
                 :filtered_list,
                 user_id: user.id,
                 parent_id: parent_search_query.id
        end

        it "creates a new search query with the existing filter" do
          expect {
            service.call(full_list_of_cases)
          }.to change(SearchQuery, :count).by(1)
        end
      end

      it "uses the full_list_of_cases for filtering" do
        @setup = StandardSetup.new only_cases: %i[
          std_unassigned_foi
          std_unassigned_irt
          std_closed_foi
          std_closed_irt
        ]
        resulting_cases = service.call(Case::Base.in_states("unassigned"))
        expect(resulting_cases).to eq [@setup.std_unassigned_foi]
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
