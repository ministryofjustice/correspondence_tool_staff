require 'rails_helper'

describe CaseSearchService do

  describe '#call' do

    let(:user)                      { create :manager }
    let(:decorated_result_set)      { double 'Decorated result set'}
    let(:paginated_result_set)      { double 'Paginated Result Set', decorate: decorated_result_set }
    let(:unpaginated_result_set)    { double 'Unpaginated Result Set', page: paginated_result_set }

    # let(:unassigned_case)           { create :case }
    # let(:assigned_case)             { create :assigned_case }

    let(:service)                   { CaseSearchService.new(user, params) }
    let(:params)                    { ActionController::Parameters.new({query: specific_query, controller: 'cases', action: 'search'}) }


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
    end

    context 'no results' do
      let(:specific_query)  { 'query resulting in no hits'}
      it 'errors' do
        service.call
        expect(service.error?).to be true
      end
      it 'populates the error message' do
        service.call
        expect(service.error_message).to eq 'No cases found'
      end
    end

    context 'with results' do
      before(:all) do
        @assigned_case = create :assigned_case
        @unassigned_case = create :case
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
        end

        context 'leading and trailing whitespace' do
          let(:specific_query)      { '   assigned  ' }
          it 'ignores leading and trailing whitespace' do
            service.call
            expect(service.result_set).to eq [ @assigned_case ]
          end
        end
      end

      context 'pagination' do
        it 'passes the page param to the paginator' do
          paged_cases = double('Paged Cases', decorate: [])
          cases = double('Cases', page: paged_cases, empty?: true)
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
        decorated_result_set = double 'Decorated result set', empty?: true
        paginated_result_set = double 'Paginated result set', decorate: decorated_result_set
        unpaginated_result_set = double 'Unaginated result set', page: paginated_result_set
        policy_scope = double 'Pundit Policy Scope'

        allow(Pundit).to receive(:policy_scope!).and_return(policy_scope)
        allow(policy_scope).to receive(:search).with('my scoped query').and_return(unpaginated_result_set)
        service.call
        expect(Pundit).to have_received(:policy_scope!).with(user, Case::Base)
      end
    end
  end
end
