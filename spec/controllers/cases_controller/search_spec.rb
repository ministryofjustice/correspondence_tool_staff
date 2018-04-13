require "rails_helper"

describe CasesController, type: :controller do

  let(:responder)             { create :responder }
  let(:responding_team)       { responder.responding_teams.first }
  let(:unassigned_case)       { create(:case) }
  let(:assigned_case)         { create :assigned_case,
                                        responding_team: responding_team }

  describe 'GET search' do
    before(:each) do
      sign_in responder
    end

    it 'renders the index template' do
      get :search
      expect(response).to render_template(:search)
    end

    it 'finds a case by number' do
      assigned_case.update_index
      get :search, params: { query: assigned_case.number }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'finds a case by text' do
      assigned_case.update_index
      unassigned_case.update_index
      get :search, params: { query: 'assigned' }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'ignores leading or trailing whitespace' do
      assigned_case.update_index
      get :search, params: { query: " #{assigned_case.number} " }
      expect(assigns[:cases]).to eq [assigned_case]
    end

    it 'sets the query hash in the flash' do
      assigned_case.update_index
      allow_any_instance_of(CaseSearchService).to receive(:query_hash).and_return('ABC124')
      get :search, params: { query: " #{assigned_case.number} " }
      expect(controller.flash[:query_hash]).to eq 'ABC124'
    end


    it 'passes the page param to the paginator' do
      paged_cases = double('Paged Cases', decorate: [])
      cases = double('Cases', page: paged_cases, empty?: true, size: 0)
      allow(Case::Base).to receive(:search).and_return(cases)
      get :search, params: { query: assigned_case.number, page: 'our_pages' }
      expect(cases).to have_received(:page).with('our_pages')
    end
  end
end
