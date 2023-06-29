require "rails_helper"

describe "assignments/assign_to_team_member.html.slim", type: :view do
  let(:assigned_case)   { create :accepted_complaint_case }
  let(:assignment)      { assigned_case.responder_assignment }

  it "displays the edit assignment page" do
    assign(:case, assigned_case)
    assign(:assignment, assigned_case.assignments.new)
    assign(:team_users, assigned_case.responding_team_users.decorate)

    render

    assign_to_team_member_page.load(rendered)

    page = assign_to_team_member_page

    expect(page.page_heading.heading.text)
        .to eq "Assign to a responder"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{assigned_case.number} "

    expect(page.team_members.users.count).to eq 1

    expect(page.confirm_button.value).to eq "Assign responder"
  end
end
