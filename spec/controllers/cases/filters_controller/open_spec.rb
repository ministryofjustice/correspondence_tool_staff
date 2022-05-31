require "rails_helper"

describe Cases::FiltersController, type: :controller do
  let(:user) { find_or_create :disclosure_bmt_user }
  let(:open_cases) { Case::Base.opened }

  let(:current_page) {
    instance_double(GlobalNavManager::Page, cases: open_cases)
  }

  let(:global_nav_manager) {
    instance_double(GlobalNavManager, current_page_or_tab: current_page)
  }

  let(:search_query) {
    create :search_query, :simple_list, filter_case_type: ['foi-standard']
  }

  let(:parent_search_query) { create :search_query, :simple_list }

  let(:case_search_service) {
    instance_double CaseSearchService,
      call: nil,
      error?: false,
      result_set: Case::Base.all,
      query: search_query,
      parent: nil
  }

  describe '#open' do
    context 'as an anonymous user' do
      it 'be redirected to signin if trying to list of questions' do
        get :open
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as an authenticated user' do
      before do
        sign_in user
        allow(CaseSearchService).to receive(:new).and_return(case_search_service)
        allow(GlobalNavManager).to receive(:new).and_return(global_nav_manager)
      end

      context 'no search_query params passed in' do
        it 'instantiates CaseSearchService with empty params' do
          get :open, params: {}
          expected_query_params = ActionController::Parameters.new(
            {
              list_path: '/cases/open'
            }
          ).permit!
          expect(CaseSearchService).to have_received(:new).with(
                                         user: user,
                                         query_type: :list,
                                         query_params: expected_query_params
                                       )
        end
      end

      context 'search_query params passed in' do
        let(:params) {
          {
            search_query: {
              parent_id: parent_search_query.id,
              filter_case_type: ['foi-standard']
            }
          }
        }

        it 'instantiates CaseSearchService with permitted params' do
          get :open, params: params
          expected_query_params = ActionController::Parameters.new({
            parent_id: parent_search_query.id.to_s,
            filter_case_type: ['foi-standard'],
            list_path: '/cases/open'
          }).permit!

          expect(CaseSearchService).to have_received(:new).with(
            user: user,
            query_type: :list,
            query_params: expected_query_params
          )
        end
      end

      it 'calls CaseSearchService with results of GlobalNavManager' do
        get :open
        expect(case_search_service).to have_received(:call).with(open_cases, order: nil)
      end

      it 'assigns the result set from the CaseFinderService' do
        get :open
        expect(assigns(:cases).object.to_sql)
          .to include("ORDER BY (cases.properties ->> 'external_deadline')")
        expect(assigns(:cases).current_page).to eq 1
        expect(assigns(:cases)).to be_decorated
      end

      it 'passes page param to the paginator' do
        get :open, params: { page: '2' }
        expect(assigns(:cases).current_page).to eq 2
      end

      it 'renders the index template' do
        get :open
        expect(response).to render_template(:index)
      end

      it 'assigns to filter_crumbs' do
        params = {
          search_query: {
            filter_case_type: ['foi-standard'],
            parent_id: parent_search_query.id
          }
        }

        get :open, params: params
        expect(case_search_service)
        expect(assigns(:filter_crumbs)[0][0]).to eq 'FOI - Standard'
      end
    end
  end
end
