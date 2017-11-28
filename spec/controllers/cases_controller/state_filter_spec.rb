require 'rails_helper'

RSpec.describe CasesController, type: :controller do

  let(:params) do
    {
      'state_selector' => {
        'unassigned'                        => '1',
        'awaiting_responder'                => '1',
        'drafting'                          => '0',
        'awaiting_dispatch'                 => '0',
        'pending_dacu_clearance'            => '1',
        'pending_press_office_clearance'    => '0',
        'pending_private_office_clearance'  => '0',
        'responded'                         => '0'
      },
      'states' => 'pending_press_office_clearance,pending_dacu_clearance,drafting',
      'timeliness' => 'in_time',
      'tab' => 'in_time',
      'other_param' => 'other_value',
      'controller' => 'cases',
      'orig_action' => 'open_cases',
      'commit' => 'Filter',
      'action' => 'filter'
    }
  end

  describe 'POST filter' do
    context 'filtering by state' do

      before(:each) do
        sign_in create(:manager)
        post :filter, params: params
        @redirect_url = URI.parse response.redirect_url
        @redirect_params = CGI.parse(@redirect_url.query)
      end

      it 'redirects to original action path' do
        expect(@redirect_url.path).to eq '/cases/open/in_time'
      end

      it 'passes on any other params' do
        expect(@redirect_params['other_param']).to eq ['other_value']
      end

      it 'replaces any states params with what was specified in state_selector' do
        expect(@redirect_params['states']).to eq ['awaiting_responder,pending_dacu_clearance,unassigned']
      end
    end

    it 'removes the page parameter' do
      sign_in create(:manager)
      my_params = params.merge('page' => '3')
      post :filter, params: my_params
      redirect_url = URI.parse response.redirect_url
      redirect_params = CGI.parse(redirect_url.query)

      expect(redirect_params).not_to have_key('page')
    end
  end

end

