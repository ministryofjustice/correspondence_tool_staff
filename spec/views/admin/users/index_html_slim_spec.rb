require "rails_helper"

describe "admin/users/index.html.slim", type: :view do
  it "displays the users provided" do
    responder = find_or_create :foi_responder
    approver = create :approver
    assign(:users, User.where(id: [responder.id, approver.id]).page(1).decorate)
    assign(:active_users_count, [responder, approver].size)

    render
    users_index_page.load(rendered)

    expect(users_index_page.active_users.text).to eq "2 active users"

    first_user_row = users_index_page.users.first
    expect(first_user_row.full_name.text).to eq responder.full_name
    expect(first_user_row.email.text).to eq responder.email
    second_user_row = users_index_page.users.second
    expect(second_user_row.full_name.text).to eq approver.full_name
    expect(second_user_row.email.text).to eq approver.email
  end
end
