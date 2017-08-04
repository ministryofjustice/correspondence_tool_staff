require 'rails_helper'

describe 'users/new.html.slim', type: :view do
  let(:dacu) { create :team_dacu }

  it 'populates the team_id if team is set' do
    assign(:user, User.new)
    assign(:team, dacu)
    render
    users_new_page.load(rendered)
    expect(users_new_page.team_id.value).to eq dacu.id.to_s
  end
end
