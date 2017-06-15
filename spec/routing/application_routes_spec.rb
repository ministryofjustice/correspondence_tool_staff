require 'rails_helper'

describe 'application routes', type: :routing do
  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  describe '/ redirects', type: :request do
    before do
      login_as user
      get '/'
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
end
