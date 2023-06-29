require "rails_helper"

describe "users/new.html.slim", type: :view do
  let(:dacu) { find_or_create :team_dacu }

  it "populates the team_id and role if team is set" do
    assign(:user, User.new)
    assign(:team, dacu)
    assign(:role, "responder")
    render
    users_new_page.load(rendered)
    expect(users_new_page.page_heading.heading)
      .to have_text "New team member"
    expect(users_new_page.page_heading.sub_heading)
      .to have_text "Business unit: Disclosure"
    expect(users_new_page.team_id.value).to eq dacu.id.to_s
    expect(users_new_page.role.value).to eq "responder"
  end
end
