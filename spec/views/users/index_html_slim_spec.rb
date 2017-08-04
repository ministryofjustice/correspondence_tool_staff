require 'rails_helper'

describe 'users/index.html.slim', type: :view do
  it 'displays the users provided' do
    responder = create :responder
    approver = create :approver
    assign(:users, [responder, approver])

    render
    users_index_page.load(rendered)

    first_user_row = users_index_page.users.first
    expect(first_user_row.full_name.text).to eq responder.full_name
    expect(first_user_row.email.text).to eq responder.email
    second_user_row = users_index_page.users.second
    expect(second_user_row.full_name.text).to eq approver.full_name
    expect(second_user_row.email.text).to eq approver.email
  end
end
