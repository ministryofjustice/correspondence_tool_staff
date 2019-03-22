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
      it { should redirect_to '/cases/open' }
    end

    context 'responder user' do
      let(:user) { responder }
      it { should redirect_to '/cases/open' }
    end

    context 'approver user' do
      let(:user) { approver }
      it { should redirect_to '/cases/open' }
    end
  end

  describe get: '/cases/closed' do
    it { should route_to 'cases#closed_cases' }
  end

  describe get: '/cases/deleted' do
    it { should route_to 'cases#deleted_cases' }
  end

  describe get: '/cases/incoming' do
    it { should route_to 'cases#incoming_cases' }
  end

  describe '/cases/my_open', type: :request  do
    before do
      get '/cases/my_open'
    end

    it { should redirect_to '/cases/my_open/in_time' }
  end

  describe get: '/cases/my_open/in_time' do
    it { should route_to 'cases#my_open_cases', tab: 'in_time' }
  end

  ###################################
  ### State Machine Event Actions ###
  ###################################
  describe patch: '/cases/1/unflag_for_clearance' do
    it { should route_to 'cases#unflag_for_clearance', id: '1' }
  end

  describe patch: '/cases/1/flag_for_clearance' do
    it { should route_to 'cases#flag_for_clearance', id: '1' }
  end

  describe get: '/cases/1/approve' do
    it { should route_to 'cases#approve', id: '1' }
  end

  describe patch: '/cases/1/approve' do
    it { should route_to 'cases#execute_approve', id: '1' }
  end

  describe get: '/cases/1/upload_responses' do
    it { should route_to 'cases#upload_responses', id: '1' }
  end

  describe patch: '/cases/1/upload_responses' do
    it { should route_to 'cases#execute_upload_responses', id: '1' }
  end

  describe get: '/cases/1/upload_response_and_approve' do
    it { should route_to 'cases#upload_response_and_approve', id: '1' }
  end

  describe patch: '/cases/1/upload_response_and_approve' do
    it { should route_to 'cases#execute_upload_response_and_approve', id: '1' }
  end

  describe get: '/cases/1/upload_response_and_return_for_redraft' do
    it { should route_to 'cases#upload_response_and_return_for_redraft',
                         id: '1' }
  end

  describe patch: '/cases/1/upload_response_and_return_for_redraft' do
    it { should route_to 'cases#execute_upload_response_and_return_for_redraft',
                         id: '1' }
  end
end
