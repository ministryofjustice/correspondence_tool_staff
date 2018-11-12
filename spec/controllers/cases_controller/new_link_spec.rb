require "rails_helper"

describe CasesController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }
  let(:kase)    { create :case}

  before do
    sign_in manager
  end

  it 'authorizes' do
    expect { get :new_case_link, params: { id: kase.id } }
      .to require_permission(:new_case_link?)
            .with_args(manager, kase)
  end

  it 'sets @case' do
    get :new_case_link, params: { id: kase.id }
    expect(assigns(:case)).to eq kase
  end

  it 'renders the template' do
    get :new_case_link, params: { id: kase.id }
    expect(response).to render_template(:new_case_link)
  end

end
