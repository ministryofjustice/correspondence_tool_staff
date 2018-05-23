require "rails_helper"

describe CasesController, type: :controller do

  let(:responder)             { create :responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:unassigned_case)       { create(:case, :indexed) }
  let(:assigned_case)         { create :assigned_case, :indexed,
                                       responding_team: responding_team }

  describe 'GET search' do
    let(:search_query)        { create :search_query }
    let(:case_search_service) { instance_double CaseSearchService,
                                                call: nil,
                                                error?: false,
                                                result_set: [],
                                                query: search_query,
                                                parent: nil }

    before(:each) do
      sign_in responder
    end

    it 'renders the search template' do
      get :search
      expect(response).to render_template(:search)
    end

    it 'finds a case by number' do
      get :search, params: { search_query: { search_text: assigned_case.number } }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'finds a case by text' do
      get :search, params: { search_query: { search_text: assigned_case.subject } }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'ignores leading or trailing whitespace' do
      get :search, params: { search_query: { search_text: " #{assigned_case.number} "} }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'uses the CaseSearchService' do
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      params = { search_query: { search_text: assigned_case.subject } }
      get :search, params: params
      controller_params = ActionController::Parameters.new(
        search_query: ActionController::Parameters.new(params[:search_query]),
      )
      expect(CaseSearchService).to have_received(:new)
                                     .with(responder, controller_params)
      expect(case_search_service).to have_received(:call)
    end

    it 'sets the query for the view' do
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      get :search, params: { search_query: { search_text: assigned_case.subject } }
      expect(assigns[:query]).to eq search_query
    end

    it 'sets the query id in the flash' do
      get :search, params: { search_query: { search_text: assigned_case.subject } }
      search_query = SearchQuery.last
      expect(flash[:query_id]).to eq search_query.id
    end

    it 'assigns to filter_crumbs' do
      parent_query = create :search_query
      params = {
        search_query: { filter_sensitivity: ['trigger'],
                        parent_id: parent_query.id}
      }
      get :search, params: params
      expect(assigns(:filter_crumbs)[0][0]).to eq 'Trigger'
    end

    context 'search does not have a parent' do
      it 'sets the parent_id to the current search_query id' do
        allow(CaseSearchService).to receive(:new).and_return(case_search_service)
        get :search, params: { search_query: { search_text: assigned_case.subject } }
        expect(assigns[:parent_id]).to eq search_query.id
      end
    end

    context 'search query has a parent (e.g. search query is a filter)' do
      it 'sets the parent_id to the created filter search query' do
        allow(CaseSearchService).to receive(:new).and_return(case_search_service)
        filter_search_query = create :search_query,
                                     :filter,
                                     parent_id: search_query.id
        allow(case_search_service).to receive(:query).and_return(filter_search_query)
        allow(case_search_service).to receive(:parent).and_return(search_query)
        get :search, params: { search_query: { filter_sensitivity: 'trigger'  } }
        expect(assigns[:parent_id]).to eq filter_search_query.id
      end
    end

    it 'passes the page param to the paginator' do
      paged_cases = double('Paged Cases', decorate: [])
      cases = double('Cases', page: paged_cases, empty?: true, size: 0)
      allow(Case::Base).to receive(:search).and_return(cases)
      get :search, params: { search_query: { search_text: assigned_case.number },
                             page: 'our_pages' }
      expect(cases).to have_received(:page).with('our_pages')
    end

    context 'no search query' do
      it 'instantiates a new SearchQuery object' do
        get :search, params: {}
        expect(assigns[:query]).to be_an_instance_of(SearchQuery)
        expect(assigns[:query][:search_text]).to be_blank
      end
    end

    context 'no search text' do
      it 'sets the alert flash' do
        get :search, params: { search_query: { search_text: '' } }
        expect(flash[:alert]).to eq 'Specify what you want to search for'
      end
    end
  end
end
