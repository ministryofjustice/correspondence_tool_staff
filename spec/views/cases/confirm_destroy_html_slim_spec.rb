require 'rails_helper'

describe 'cases/confirm_destroy.html.slim', type: :view do
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  let(:kase)   { create :accepted_case }
  let(:manager){ create :manager }

  before do
    login_as manager
  end

  it 'displays the delete confirmation page' do
    assign(:case, kase)

    render

    confirm_destroy_page.load(rendered)

    page = confirm_destroy_page

    expect(page.page_heading.heading.text).to eq "Delete case"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{kase.number} "

    expect(page.delete_copy.text).to eq "You are deleting the case: #{kase.subject}"

    expect(page).to have_warning
    expect(page).to have_reason_for_deletion

    expect(page.confirm_button_text).to eq "Delete case"
    expect(page).to have_cancel

  end
end
