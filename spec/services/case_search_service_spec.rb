require 'rails_helper'

describe CaseSearchService do

  let(:user)                      { create :manager }

  describe '#call' do
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

    context 'no parent id specified' do
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
        before(:all) do
          @assigned_case = create :assigned_case
          @unassigned_case = create :case
          Case::Base.update_all_indexes
        end

        after(:all)   { DbHousekeeping.clean }

        context 'search by number' do
          let(:specific_query)       { @assigned_case.number }

          it 'finds a case by number' do
            service.call
            expect(service.result_set).to eq [ @assigned_case ]
          end

        end

        context 'search by text' do
          context 'no leading or trailing whitespace' do
            let(:specific_query)   { 'assigned' }
            it 'finds a case by text' do
              service.call
              expect(service.result_set).to eq [ @assigned_case ]
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
            let(:specific_query)      { '   assigned  ' }
            it 'ignores leading and trailing whitespace' do
              service.call
              expect(service.result_set).to eq [ @assigned_case ]
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


    context 'parent id specified' do
      after(:all)   { DbHousekeeping.clean }

      let!(:parent_search_query) { create :search_query, search_text: search_text }
      let(:filter_case_type)     { ['foi-standard'] }
      let(:filter_sensitivity)   { [''] }
      let(:params) { ActionController::Parameters.new(
                       {
                         search_query: {
                           parent_id: parent_search_query.id,
                           filter_case_type: filter_case_type,
                           filter_sensitivity: filter_sensitivity,
                         },
                       }
                     ) }
      let(:search_text) { 'compliance' }
      let(:service)     { CaseSearchService.new(user, params) }

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
      end

      it 'performs the search using the SearchQuery' do
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
        before(:all) do
          @search = StandardSetup.new(only_cases: [
                                        :std_draft_foi,
                                        :trig_closed_foi,
                                        :std_unassigned_irc,
                                        :std_unassigned_irt,
                                      ])
          Case::Base.update_all_indexes
        end

        context 'search text' do
          let(:search_text)        { 'closed'}
          let(:filter_case_type)   { [] }
          let(:filter_sensitivity) { [] }

          it 'is used' do
            service.call
            expect(service.unpaginated_result_set)
              .to match_array [@search.trig_closed_foi]
          end
        end

        context 'filter for sensitivity' do
          let(:search_text)        { 'case'}
          let(:filter_case_type)   { [] }
          let(:filter_sensitivity) { ['trigger'] }

          it 'is used' do
            service.call
            expect(service.unpaginated_result_set)
              .to match_array [@search.trig_closed_foi]
          end
        end

        context 'filter for case type' do
          let(:search_text)        { 'case'}
          let(:filter_case_type)   { ['foi-standard'] }
          let(:filter_sensitivity) { [''] }

          it 'is used' do
            service.call
            expect(service.unpaginated_result_set)
              .to match_array [
                    @search.std_draft_foi,
                    @search.trig_closed_foi,
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

    end

  end
end

