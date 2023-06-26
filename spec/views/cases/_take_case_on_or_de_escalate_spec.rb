require "rails_helper"

describe "cases/shared/_take_case_on_or_de_escalate.slim", type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  let(:dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:approver)        do
    create :approver,
           approving_team: dacu_disclosure
  end
  let(:assigned_case) do
    create :assigned_case, :flagged_accepted,
           approver:
  end
  let(:partial) do
    render partial: "cases/shared/take_case_on_or_de_escalate",
           locals: { case_details: assigned_case }
    cases_what_do_you_want_to_do_section(rendered)
  end

  before do
    login_as approver
    allow_case_policies_in_view(assigned_case, :unflag_for_clearance?)
  end

  it "has a link to take the case on" do
    expect(partial).to have_take_case_on_link
  end

  it "has a link to de-escalate the case" do
    expect(partial).to have_de_escalate_link
  end
end
