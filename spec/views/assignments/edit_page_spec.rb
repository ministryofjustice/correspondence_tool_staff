require 'rails_helper'

describe 'assignments/edit.html.slim', type: :view do
  let(:assigned_case)   { create :assigned_case }
  let(:assignment)      { assigned_case.responder_assignment }

  it 'displays the edit assignment page' do

    assign(:case, assigned_case)
    assign(:assignment, assignment)

    render

    assignments_edit_page.load(rendered)

    page = assignments_edit_page

    expect(page.page_heading.heading.text).to eq assigned_case.subject
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{assigned_case.number} "

    expect(page.message.text).to eq assigned_case.message

    expect(page.confirm_button.value).to eq "Confirm"

  end

end
