require 'rails_helper'

describe 'assignments/show_rejected.html.slim', type: :view do
  let(:rejected_case)   { create :rejected_case }

  it 'displays the show rejected page for a case that has just been rejected ' do
    assign(:case, rejected_case)
    assign(:rejected_now, 'true')
    #assign(:assignment, assignment)

    render

    assignment_rejected_page.load(rendered)

    page = assignment_rejected_page

    expect(page.new_rejection_notice.text).
        to eq "You've rejected this case\nDACU BMT will assign the case to the appropriate business unit.\n"

    expect(page.page_heading.heading.text).to eq rejected_case.subject
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{rejected_case.number} "

    expect(page.message_label.text).to eq "Request"
    expect(page.message.text).to eq rejected_case.message


  end

  it 'displays the show rejected page for a case that has just been rejected ' do
    assign(:case, rejected_case)
    #assign(:assignment, assignment)

    render

    assignment_rejected_page.load(rendered)

    page = assignment_rejected_page

    expect(page.already_rejected_notice.text).
        to eq "This case has already been rejected.\nThis case will be reviewed and assigned the to appropriate unit.\n"

    expect(page.page_heading.heading.text).to eq rejected_case.subject
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{rejected_case.number} "

    expect(page.message_label.text).to eq "Request"
    expect(page.message.text).to eq rejected_case.message
  end


end
