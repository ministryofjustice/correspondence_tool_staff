require 'rails_helper'

describe CaseSearchService do

  let(:user)                      { create :manager }

  describe '#call' do


    let(:decorated_result_set)      { double 'Decorated result set'}
    let(:paginated_result_set)      { double 'Paginated Result Set', decorate: decorated_result_set }
    let(:unpaginated_result_set)    { double 'Unpaginated Result Set', page: paginated_result_set }

    let(:service)                   { CaseSearchService.new(user, params) }
    let(:params)                    { ActionController::Parameters.new({query: specific_query, controller: 'cases', action: 'search'}) }

    context 'no parent hash specified' do

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
          expect(sq.query_hash).to eq service.query_hash
          expect(sq.query).to eq specific_query
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
              expect(sq.query_hash).to eq service.query_hash
              expect(sq.query).to eq specific_query
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
              expect(sq.query_hash).to eq service.query_hash
              expect(sq.query).to eq specific_query.strip
              expect(sq.num_results).to eq 1
            end
          end
        end

        context 'pagination' do
          it 'passes the page param to the paginator' do
            paged_cases = double('Paged Cases', decorate: [])
            cases = double('Cases', page: paged_cases, empty?: true, size: 0)
            allow(Case::Base).to receive(:search).and_return(cases)
            params = ActionController::Parameters.new({query: 'xx', page: '3', controller: 'cases', action: 'search'})
            service = CaseSearchService.new(user, params)
            service.call
            expect(cases).to have_received(:page).with('3')
          end
        end
      end

      context 'use of the policy scope' do
        let(:specific_query)    { 'my scoped query' }
        it 'uses the policy scope' do
          decorated_result_set = double 'Decorated result set', empty?: true, size: 0
          paginated_result_set = double 'Paginated result set', decorate: decorated_result_set
          unpaginated_result_set = double 'Unpaginated result set', page: paginated_result_set, size: 0
          policy_scope = double 'Pundit Policy Scope'

          allow(Pundit).to receive(:policy_scope!).and_return(policy_scope)
          allow(policy_scope).to receive(:search).with('my scoped query').and_return(unpaginated_result_set)
          service.call
          expect(Pundit).to have_received(:policy_scope!).with(user, Case::Base)
        end
      end

    end

    context 'parent hash specified' do

      before(:all) do
        @foi_1 = create :case, subject: 'dogs in prison'
        @foi_2 = create :case, subject: 'dogs in jail'
        @foi_3 = create :case, subject: 'dog eat dog mentality'
        @irc_1 = create :compliance_review, subject: 'dogs in prison compliance review'
        @irc_2 = create :compliance_review, subject: 'jail dog compliance review'
        @irt_1 = create :timeliness_review, subject: 'dogs in prison timeliness review'
        @irt_2 = create :timeliness_review, subject: 'jail dog timeliness review'
        Case::Base.update_all_indexes
      end

      after(:all)   { DbHousekeeping.clean }

      context 'parent search query is the root' do
        let(:params)            { ActionController::Parameters.new({filter: 'type', query: 'internal_review'}) }

        before(:each) do
          @sq = create :search_query,
                      user_id: user.id,
                      query_hash: 'ROOT SEARCH QUERY',
                      query: 'dogs',
                      parent_id: nil,
                      num_results: 7
          @service = CaseSearchService.new(user, params, 'ROOT SEARCH QUERY')
        end

        it 'performs the parent_search first and then the CaseFilterService' do
          expect_any_instance_of(Case::Base::ActiveRecord_Relation).to receive(:search).with('dogs').and_call_original
          expect(CaseFilterService).to receive(:new).with(instance_of(Case::Base::ActiveRecord_Relation), instance_of(SearchQuery)).and_call_original
          @service.call
        end

        it 'returns just the internal review cases' do
          @service.call
          expect(@service.unpaginated_result_set.map(&:id)).to eq( [ @irc_1.id, @irc_2.id, @irt_1.id, @irt_2.id ] )
        end

        it 'writes a child search query record' do
          @service.call
          expect(SearchQuery.count).to eq 2
          sq = SearchQuery.last
          expect(sq.user_id).to eq user.id
          expect(sq.parent_id).to eq @sq.id
          expect(sq.filter_type).to eq 'type'
          expect(sq.query).to eq 'internal_review'
          expect(sq.num_results).to eq 4
        end
      end

      context 'parent search query is a child' do
        let(:params)            { ActionController::Parameters.new({filter: 'type', query: 'compliance'}) }

        before(:each) do
          @sq_root = create :search_query,
                            user_id: user.id,
                            query_hash: 'ROOT SEARCH QUERY',
                            query: 'dogs',
                            parent_id: nil,
                            num_results: 7
          @sq_parent = create :search_query, :filter,
                              user_id: user.id,
                              query_hash: 'PARENT FILTER QUERY',
                              filter_type: 'filter',
                              query: 'internal_review',
                              parent_id: @sq_root.id,
                              num_results: 4

          @service = CaseSearchService.new(user, params, 'PARENT FILTER QUERY')
        end

        it 'performs the parent searches and filters first and then the CaseFilterService' do
          expect_any_instance_of(Case::Base::ActiveRecord_Relation).to receive(:search).with('dogs').and_call_original
          expect(CaseFilterService).to receive(:new).with(instance_of(Case::Base::ActiveRecord_Relation), instance_of(SearchQuery)).exactly(2).and_call_original
          @service.call
        end

        it 'returns just the internal review for compliance cases' do
          @service.call
          expect(@service.unpaginated_result_set.map(&:id)).to eq( [ @irc_1.id, @irc_2.id ] )
        end

        it 'writes a grandchild search query record' do
          @service.call
          expect(SearchQuery.count).to eq 3
          sq = SearchQuery.last
          expect(sq.user_id).to eq user.id
          expect(sq.parent_id).to eq @sq_parent.id
          expect(sq.filter_type).to eq 'type'
          expect(sq.query).to eq 'compliance'
          expect(sq.num_results).to eq 2
        end
      end


      context 'parent hash does not exist in database' do

        let(:params)    { ActionController::Parameters.new({filter: 'type', query: 'internal_review'}) }

        it 'raises' do
          @service = CaseSearchService.new(user, params, 'NON-EXISTENT HASH')
          expect {
            @service .call
          }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find SearchQuery"
        end
      end

    end

  end
end

