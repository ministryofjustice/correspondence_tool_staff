require 'rails_helper'

describe 'cases filters routes', type: :routing do
  describe '/cases/filters redirects', type: :request do
    describe get: '/cases/closed' do
      it { should route_to controller: 'cases/filters', action: 'closed' }
    end

    describe get: '/cases/deleted' do
      it { should route_to controller: 'cases/filters', action: 'deleted' }
    end

    describe get: '/cases/incoming' do
      it { should route_to controller: 'cases/filters', action: 'incoming' }
    end

    describe '/cases/my_open', type: :request  do
      before do
        get '/cases/my_open'
      end

      it { should redirect_to '/cases/my_open/in_time' }
    end

    describe get: '/cases/my_open/in_time' do
      it { should route_to controller: 'cases/filters', action: 'my_open', tab: 'in_time' }
    end
  end
end
