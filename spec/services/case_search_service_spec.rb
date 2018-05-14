require 'rails_helper'

describe CaseSearchService do

  let(:user)                      { create :manager }

  describe '#call' do
    before(:all) do
      @setup = StandardSetup.new(only_cases: [
                                   :std_draft_foi,
                                   :trig_closed_foi,
                                   :std_unassigned_irc,
                                   :std_unassigned_irt,
                                 ])
      Case::Base.update_all_indexes
    end

    let(:service)      { CaseSearchService.new(user, params) }
    let(:params)       { ActionController::Parameters.new(
                           {
                             search_query: { search_text: specific_query },
                             controller: 'cases',
                             action: 'search'
                           }
                         ) }

    context 'use of the policy scope' do
      let(:specific_query)    { 'my scoped query' }
      it 'uses the for_view_only policy scope' do
        expect(Case::BasePolicy::Scope).to receive(:new).with(user, Case::Base.all).and_call_original
        expect_any_instance_of(Case::BasePolicy::Scope).to receive(:for_view_only).and_call_original
        service.call
      end
    end

    context 'filtering on search results' do

      context 'performing fresh search (with no existing search)' do
        let(:specific_query) { 'something' }

        it 'sets search_query type to search' do
          service.call
          search_query = SearchQuery.last
          expect(search_query.query_type).to eq 'search'
        end

        context 'blank query' do
          let(:specific_query)      { '  ' }
          it 'errors' do
            service.call
            expect(service.error?).to be true
          end

          it 'populates the error message' do
            service.call
            expect(service.error_message).to eq 'Specify what you want to search for'
          end

          it 'does not record a search_query record' do
            expect(SearchQuery.count).to eq 0
          end
        end

        context 'no results' do
          let(:specific_query)  { 'query resulting in no hits'}

          it 'records a search_query record' do
            service.call
            expect(SearchQuery.count).to eq 1
            sq = SearchQuery.first
            expect(sq.search_text).to eq specific_query
            expect(sq.num_results).to eq 0
          end
        end

        context 'with results' do
          context 'search by number' do
            let(:specific_query)       { @setup.std_draft_foi.number }

            it 'finds a case by number' do
              service.call
              expect(service.result_set).to eq [ @setup.std_draft_foi ]
            end

          end

          context 'search by text' do
            context 'no leading or trailing whitespace' do
              let(:specific_query)   { 'accepted' }
              it 'finds a case by text' do
                service.call
                expect(service.result_set).to eq [ @setup.std_draft_foi ]
              end

              it 'records a search_query record' do
                service.call
                expect(SearchQuery.count).to eq 1
                sq = SearchQuery.first
                expect(sq.search_text).to eq specific_query
                expect(sq.num_results).to eq 1
              end
            end

            context 'leading and trailing whitespace' do
              let(:specific_query)      { '   accepted  ' }
              it 'ignores leading and trailing whitespace' do
                service.call
                expect(service.result_set).to eq [ @setup.std_draft_foi ]
              end

              it 'records a search_query record' do
                service.call
                expect(SearchQuery.count).to eq 1
                sq = SearchQuery.first
                expect(sq.search_text).to eq specific_query.strip
                expect(sq.num_results).to eq 1
              end
            end
          end

          context 'pagination' do
            it 'passes the page param to the paginator' do
              paged_cases = double('Paged Cases', decorate: [])
              cases = double('Cases', page: paged_cases, empty?: true, size: 0)
              allow(Case::Base).to receive(:search).and_return(cases)
              params = ActionController::Parameters.new(
                {
                  search_query: { search_text: 'xx' },
                  page: '3',
                  controller: 'cases',
                  action: 'search'
                })
              service = CaseSearchService.new(user, params)
              service.call
              expect(cases).to have_received(:page).with('3')
            end
          end
        end
      end

      context 'applying filter on search results' do
        let!(:parent_search_query)       { create :search_query,
                                              search_text: search_text,
                                              user_id: user.id }
        let(:filter_case_type)           { ['', 'foi-standard'] }
        let(:filter_sensitivity)         { [''] }
        let(:external_deadline_from)     { 0.business_days.from_now.to_date }
        let(:external_deadline_to)       { 10.business_days.from_now.to_date }

        let(:params) { ActionController::Parameters.new(
                         {
                           search_query: {
                             parent_id: parent_search_query.id,
                             filter_case_type: filter_case_type,
                             filter_sensitivity: filter_sensitivity,
                             external_deadline_from_dd: external_deadline_from&.day.to_s,
                             external_deadline_from_mm: external_deadline_from&.month.to_s,
                             external_deadline_from_yyyy: external_deadline_from&.year.to_s,
                             external_deadline_to_dd: external_deadline_to&.day.to_s,
                             external_deadline_to_mm: external_deadline_to&.month.to_s,
                             external_deadline_to_yyyy: external_deadline_to&.year.to_s,
                           },
                         }
                       ) }
        let(:search_text) { 'compliance' }
        let(:service)     { CaseSearchService.new(user, params) }

        context 'first filter applied by user' do
          it 'creates a new search query' do
            expect {
              service.call
            }.to change(SearchQuery, :count).by(1)
          end

          describe 'created search query' do
            before(:each) { service.call }
            subject       { SearchQuery.last }

            it { should have_attributes query_type: 'filter' }
            it { should have_attributes user_id: user.id }
            it { should have_attributes search_text: 'compliance' }
            it { should have_attributes parent_id: parent_search_query.id }
            it { should have_attributes filter_case_type: filter_case_type.grep_v('') }
            it { should have_attributes filter_sensitivity: filter_sensitivity.grep_v('') }
            it { should have_attributes external_deadline_from: external_deadline_from }
            it { should have_attributes external_deadline_to: external_deadline_to }

          end
        end

        context 'user has another filter applied' do
          let!(:parent_search_query) { create :search_query,
                                              user_id: user.id,
                                              search_text: search_text,
                                              filter_status: ['open'] }

          it 'creates a new search query with the existing filter' do
            expect {
              service.call
            }.to change(SearchQuery, :count).by(1)
          end

          describe 'created search query' do
            before(:each) { service.call }
            subject       { SearchQuery.last }

            it { should have_attributes query_type: 'filter' }
            it { should have_attributes user_id: user.id }
            it { should have_attributes search_text: 'compliance' }
            it { should have_attributes parent_id: parent_search_query.id }
            it { should have_attributes filter_status: ['open'] }
            it { should have_attributes filter_case_type: filter_case_type.grep_v('') }
            it { should have_attributes filter_sensitivity: filter_sensitivity.grep_v('') }
            it { should have_attributes external_deadline_from: external_deadline_from }
            it { should have_attributes external_deadline_to: external_deadline_to }
          end
        end

        context 'search and filters have already been used by this user' do
          it 'retrieves the existing SearchQuery' do

            existing_search_query = create :search_query, :filter,
                                           search_text: search_text,
                                           user: user,
                                           parent_id: parent_search_query.id,
                                           filter_case_type: ['foi-standard'],
                                           external_deadline_from: external_deadline_from,
                                           external_deadline_to: external_deadline_to
            service.call
            expect(service.query).to eq existing_search_query
          end
        end

        it 'performs the search/filter using the SearchQuery' do
          expected_results = spy('expected results')
          search_query = instance_double(SearchQuery,
                                         results: expected_results,
                                         :num_results= => nil,
                                         save!: nil)
          allow(SearchQuery).to receive(:new).and_return(search_query)
          service.call
          expect(service.unpaginated_result_set).to eq expected_results
        end

        describe 'search results' do
          let(:filter_case_type)       { [] }
          let(:filter_sensitivity)     { [] }
          let(:external_deadline_from) { nil }
          let(:external_deadline_to)   { nil }

          context 'search text' do
            let(:search_text)            { 'closed'}

            it 'is used' do
              service.call
              expect(service.unpaginated_result_set)
                .to match_array [@setup.trig_closed_foi]
            end
          end

          context 'filter for sensitivity' do
            let(:search_text)        { 'case'}
            let(:filter_sensitivity) { ['trigger'] }

            it 'is used' do
              service.call
              expect(service.unpaginated_result_set)
                .to match_array [@setup.trig_closed_foi]
            end
          end

          context 'filter for case type' do
            let(:search_text)        { 'case'}
            let(:filter_case_type)   { ['foi-standard'] }

            it 'is used' do
              service.call
              expect(service.unpaginated_result_set)
                .to match_array [
                      @setup.std_draft_foi,
                      @setup.trig_closed_foi,
                    ]
            end
          end

          context 'filter for external deadline' do
            let(:search_text)            { 'case'}
            let(:external_deadline_from) { 0.business_days.from_now.to_date }
            let(:external_deadline_to)   { 10.business_days.from_now.to_date }

            it 'is used' do
              @setup.std_draft_foi.update(external_deadline: 2.business_days.from_now)
              service.call
              expect(service.unpaginated_result_set)
                .to match_array [
                      @setup.std_draft_foi,
                    ]
            end
          end
        end

        context 'parent id does not exist in database' do
          it 'raises' do
            parent_search_query.destroy
            expect {
              service.call
            }.to raise_error ActiveRecord::RecordNotFound,
                             /Couldn't find SearchQuery with 'id'=\d+/
          end
        end

        context 'different filter sensitivites exist already in the database' do
          let(:search_text)        { 'case'}
          let(:filter_case_type)   { ['foi-standard'] }
          let(:filter_sensitivity) { ['trigger', 'non-trigger'] }
          let(:params)       { ActionController::Parameters.new(
              {
                  search_query: { search_text: 'case', filter_sensitivity: ['trigger'] },
                  controller: 'cases',
                  action: 'search'
              }
          ) }

          it 'creates a new record' do
            create :search_query,
                   user_id: user.id,
                   search_text: 'case',
                   filter_sensitivity: ['trigger', 'non-trigger']

            expect{
              service.call
            }.to change { SearchQuery.count }.by(1)

          end
        end

      end
    end

    context 'filtering on list results' do
      let!(:parent_search_query)   { create :search_query, :list }
      let(:service)                { CaseSearchService.new(user, params) }
      let(:filter_case_type)       { ['', 'foi-standard'] }
      let(:filter_sensitivity)     { [''] }
      let(:params)    { ActionController::Parameters.new(
          {
              search_query: {
                  parent_id: parent_search_query.id,
                  filter_case_type: filter_case_type,
                  filter_sensitivity: filter_sensitivity,
              }
          })
      }

      context 'first_filter applied by user' do

        it 'creates a new search query' do
          expect {
            service.call
          }.to change(SearchQuery, :count).by(1)
          expect(SearchQuery.last.parent).to eq parent_search_query
        end
      end

      describe 'created search query' do
        before(:each) { service.call }
        subject       { SearchQuery.last }

        it { should have_attributes query_type: 'filter' }
        it { should have_attributes user_id: user.id }
        it { should have_attributes search_text: nil }
        it { should have_attributes list_path: parent_search_query.list_path }
        it { should have_attributes list_params: parent_search_query.list_params }
        it { should have_attributes parent_id: parent_search_query.id }
        it { should have_attributes filter_case_type: filter_case_type.grep_v('') }
        it { should have_attributes filter_sensitivity: filter_sensitivity.grep_v('') }
      end

      context 'user has another filter applied' do
        let(:params)    { ActionController::Parameters.new(
            {
                search_query: {
                    parent_id: child_search_query.id,
                    filter_case_type: filter_case_type,
                    filter_sensitivity: filter_sensitivity,
                }
            })
        }
        let!(:child_search_query) { create :search_query,
                                            :filtered_list,
                                            user_id: user.id,
                                            parent_id: parent_search_query.id }

        it 'creates a new search query with the existing filter' do
          expect {
            service.call
          }.to change(SearchQuery, :count).by(1)
        end
      end
    end
  end
end

