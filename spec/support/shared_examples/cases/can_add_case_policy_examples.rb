require "rails_helper"

# Ensure valid `params` are declared in parent spec
RSpec.shared_examples "can_add_case policy spec" do |klass|
  subject { post :create, params: }

  let(:user) { create(:user) }
  let(:case_class) { klass }
  let(:service) do
    instance_spy(CaseCreateService, case_type: case_class)
  end

  before do
    allow(CaseCreateService).to receive(:new).and_return(service)
  end

  it "authorises with can_add_case? policy" do
    sign_in(user)

    expect { subject }.to require_permission(:can_add_case?)
      .disallow
      .with_args(user, case_class)
  end

  it "does not create a case when authentication fails" do
    disallow_case_policies(case_class, :can_add_case?)
    sign_in user
    expect { subject }.not_to change { klass.count }
  end

  it "redirects to application root when authentication fails" do
    disallow_case_policies(case_class, :can_add_case?)
    sign_in user
    expect(subject).to redirect_to(responder_root_path)
  end
end
