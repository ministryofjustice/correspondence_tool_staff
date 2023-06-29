require "rails_helper"

describe "assignments/reassign_user.html.slim", type: :view do
  let(:assigned_case)   { create :assigned_case }
  let(:assignment)      { assigned_case.responder_assignment }

  it "displays the edit assignment page" do
    assign(:case, assigned_case)
    assign(:assignment, assignment)
    assign(:team_users, assigned_case.responding_team_users.decorate)

    render

    reassign_user_page.load(rendered)

    page = reassign_user_page

    expect(page.page_heading.heading.text)
        .to eq "Change team member"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{assigned_case.number} "

    expect(page.reassign_to.users.count).to eq 1

    expect(page.confirm_button.value).to eq "Change team member"
  end
end
