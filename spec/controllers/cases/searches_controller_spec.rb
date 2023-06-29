require "rails_helper"

describe Cases::SearchesController, type: :controller do
  let(:responder)       { find_or_create :foi_responder }
  let(:responding_team) { responder.responding_teams.first }
  let(:unassigned_case) { create(:case, :indexed) }
  let(:assigned_case) do
    create(
      :assigned_case,
      :indexed,
      responding_team:,
    )
  end

  describe "#show" do
    let(:search_query) { create :search_query }
    let(:case_search_service) do
      instance_double CaseSearchService,
                      call: nil,
                      error?: false,
                      result_set: Case::Base.none,
                      query: search_query,
                      parent: nil
    end

    before do
      sign_in responder
    end

    it "renders the search template" do
      get :show
      expect(response).to render_template(:show)
    end

    it "finds a case by number" do
      get :show, params: { search_query: { search_text: assigned_case.number } }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it "finds a case by text" do
      get :show, params: { search_query: { search_text: assigned_case.subject } }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it "ignores leading or trailing whitespace" do
      get :show, params: { search_query: { search_text: " #{assigned_case.number} " } }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it "uses the CaseSearchService" do
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      params = { search_query: { search_text: assigned_case.subject } }
      get(:show, params:)

      expected_params = ActionController::Parameters.new(
        params[:search_query],
      ).permit!

      expect(CaseSearchService).to have_received(:new).with(
        user: responder,
        query_type: :search,
        query_params: expected_params,
      )

      expect(case_search_service).to have_received(:call)
    end

    it "uses the CaseSearchService with the choice of oldest cases first" do
      request.cookies[:search_result_order] = "search_result_order_by_oldest_first"
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      params = { search_query: { search_text: assigned_case.subject } }
      get(:show, params:)

      expected_params = ActionController::Parameters.new(
        params[:search_query],
      ).permit!

      expect(CaseSearchService).to have_received(:new).with(
        user: responder,
        query_type: :search,
        query_params: expected_params,
      )

      expect(case_search_service).to have_received(:call).with(order: "search_result_order_by_oldest_first")
    end

    it "uses the CaseSearchService with the choice of newest cases first flag" do
      request.cookies[:search_result_order] = "search_result_order_by_newest_first"
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      params = { search_query: { search_text: assigned_case.subject } }
      get(:show, params:)

      expected_params = ActionController::Parameters.new(
        params[:search_query],
      ).permit!

      expect(CaseSearchService).to have_received(:new).with(
        user: responder,
        query_type: :search,
        query_params: expected_params,
      )

      expect(case_search_service).to have_received(:call).with(order: "search_result_order_by_newest_first")
    end

    it "sets the query for the view" do
      allow(CaseSearchService).to receive(:new).and_return(case_search_service)
      get :show, params: { search_query: { search_text: assigned_case.subject } }

      expect(assigns[:query]).to eq search_query
    end

    it "sets the query id in the flash" do
      get :show, params: { search_query: { search_text: assigned_case.subject } }
      search_query = SearchQuery.last

      expect(flash[:query_id]).to eq search_query.id
    end

    it "assigns to filter_crumbs" do
      parent_query = create :search_query
      params = {
        search_query: {
          filter_sensitivity: %w[trigger],
          parent_id: parent_query.id,
        },
      }
      get(:show, params:)

      expect(assigns(:filter_crumbs)[0][0]).to eq "Trigger"
    end

    context "when search does not have a parent" do
      it "sets the parent_id to the current search_query id" do
        allow(CaseSearchService).to receive(:new).and_return(case_search_service)
        get :show, params: { search_query: { search_text: assigned_case.subject } }

        expect(assigns[:parent_id]).to eq search_query.id
      end
    end

    context "when search query has a parent (e.g. search query is a filter)" do
      it "sets the parent_id to the created filter search query" do
        allow(CaseSearchService).to receive(:new).and_return(case_search_service)
        filter_search_query = create(
          :search_query,
          :filter,
          parent_id: search_query.id,
        )
        allow(case_search_service).to receive(:query).and_return(filter_search_query)
        allow(case_search_service).to receive(:parent).and_return(search_query)
        get :show, params: { search_query: { filter_sensitivity: "trigger" } }

        expect(assigns[:parent_id]).to eq filter_search_query.id
      end
    end

    it "passes the page param to the paginator" do
      paged_cases = double("Paged Cases", decorate: []) # rubocop:disable RSpec/VerifiedDoubles
      cases = double("Cases", page: paged_cases, empty?: true, size: 0) # rubocop:disable RSpec/VerifiedDoubles
      allow(Case::Base).to receive(:search_result_order_by_oldest_first).and_return(cases)
      get :show, params: {
        search_query: { search_text: assigned_case.number },
        page: "our_pages",
      }

      expect(cases).to have_received(:page).with("our_pages")
    end

    context "when no search query" do
      it "instantiates a new SearchQuery object" do
        get :show, params: {}
        expect(assigns[:query]).to be_an_instance_of(SearchQuery)
        expect(assigns[:query][:search_text]).to be_blank
      end
    end

    context "when no search text" do
      it "sets the alert flash" do
        get :show, params: { search_query: { search_text: "" } }
        expect(flash[:alert]).to eq "Specify what you want to search for"
      end
    end
  end
end
