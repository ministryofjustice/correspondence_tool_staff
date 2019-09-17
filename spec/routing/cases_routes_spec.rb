require 'rails_helper'

describe 'cases routes', type: :routing do
  let(:manager)   { create :manager }
  let(:responder) { find_or_create :foi_responder }
  let(:approver)  { create :approver }

  describe '/cases redirects', type: :request do
    before do
      login_as user
      get '/cases'
    end

    context 'manager user' do
      let(:user) { manager }
      it { should redirect_to '/cases/my_open' }
    end

    context 'responder user' do
      let(:user) { responder }
      it { should redirect_to '/cases/my_open' }
    end

    context 'approver user' do
      let(:user) { approver }
      it { should redirect_to '/cases/my_open' }
    end
  end


  ###################################
  ### State Machine Event Actions ###
  ###################################
  describe patch: '/cases/1/clearances/unflag_for_clearance' do
    it { should route_to controller: 'cases/clearances', action: 'unflag_for_clearance', case_id: '1' }
  end

  describe patch: '/cases/1/clearances/flag_for_clearance' do
    it { should route_to controller: 'cases/clearances', action: 'flag_for_clearance', case_id: '1' }
  end

  describe get: '/cases/1/approvals/new' do
    it { should route_to controller: 'cases/approvals', action: 'new', case_id: '1' }
  end

  describe post: '/cases/1/approvals' do
    it { should route_to controller: 'cases/approvals', action: 'create', case_id: '1' }
  end

  describe get: '/cases/1/responses/new/upload_responses' do
    it { should route_to controller: 'cases/responses', action: 'new', case_id: '1', response_action: 'upload_responses' }
  end

  describe get: '/cases/1/responses/new/upload_response_and_approve' do
    it { should route_to controller: 'cases/responses', action: 'new', case_id: '1', response_action: 'upload_response_and_approve' }
  end

  describe get: '/cases/1/responses/new/upload_response_and_return_for_redraft' do
    it { should route_to controller: 'cases/responses', action: 'new', case_id: '1', response_action: 'upload_response_and_return_for_redraft' }
  end

  # Note all responses action use the same create endpoint,
  # assume response_action is set as a parameter
  describe post: '/cases/1/responses' do
    it { should route_to controller: 'cases/responses', action: 'create', case_id: '1' }
  end

  describe post: '/cases/1/notes' do
    it { should route_to controller: 'cases/notes', action: 'create', case_id: '1' }
  end

  describe get: '/cases/1/letters/acknowledgement/new' do
    it { should route_to controller: 'cases/letters', action: 'new', case_id: '1', type: 'acknowledgement'}
  end

  describe get: '/cases/1/letters/acknowledgement/render' do
    it { should route_to controller: 'cases/letters', action: 'render_letter', case_id: '1', type: 'acknowledgement' }
  end
end
