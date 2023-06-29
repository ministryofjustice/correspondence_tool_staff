require "rails_helper"

RSpec.shared_examples "new case spec" do |klass|
  let(:manager) { find_or_create :disclosure_bmt_user }

  before do
    sign_in manager
  end

  it "authorizes" do
    expect { get :new, params: }
      .to require_permission(:can_add_case?)
        .with_args(manager, klass)
  end

  it "renders the new template" do
    get(:new, params:)
    expect(response).to render_template(:new)
  end

  it "assigns @case" do
    get(:new, params:)
    expect(assigns(:case)).to be_a klass
  end

  it "assigns @case_types" do
    get(:new, params:)
    expect(assigns(:case_types)).to eq case_types
  end
end
