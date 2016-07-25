require 'rails_helper'

RSpec.describe CorrespondenceController, type: :controller do

  let(:all_correspondence) { create_list(:correspondence, 5) }

  context 'GET index' do

    before { get :index }

    it 'assigns @correspondence' do
      expect(assigns(:correspondence)).to match(all_correspondence)
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end

  end

end
