require 'rails_helper'

describe 'cases routes', type: :routing do
  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  describe '/cases redirects', type: :request do
    before do
      login_as user
      get '/cases'
    end

    context 'manager user' do
      let(:user) { manager }
      it { should redirect_to '/cases/open?timeliness=in_time' }
    end

    context 'responder user' do
      let(:user) { responder }
      it { should redirect_to '/cases/open?timeliness=in_time' }
    end

    context 'approver user' do
      let(:user) { approver }
      it { should redirect_to '/cases/open?timeliness=in_time' }
    end
  end

  describe get: '/cases/closed' do
    it { should route_to 'cases#closed_cases' }
  end

  describe get: '/cases/incoming' do
    it { should route_to 'cases#incoming_cases' }
  end

  describe get: '/cases/my_open' do
    it { should route_to 'cases#my_open_cases' }
  end

  describe get: '/cases/open' do
    it { should route_to 'cases#open_cases' }
  end

  describe get: '/cases/1/assignments/show_rejected' do
    it { should route_to 'assignments#show_rejected', case_id: '1' }
  end

  describe patch: '/cases/1/unflag_for_clearance' do
    it { should route_to 'cases#unflag_for_clearance', id: '1' }
  end

  describe patch: '/cases/1/flag_for_clearance' do
    it { should route_to 'cases#flag_for_clearance', id: '1' }
  end

  describe get: '/cases/1/approve_response' do
    it { should route_to 'cases#approve_response', id: '1' }
  end

  describe post: '/cases/1/execute_response_approval' do
    it { should route_to 'cases#execute_response_approval', id: '1' }
  end

end
