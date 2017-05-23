require 'rails_helper'

describe 'cases/case_request.html.slim', type: :view do

  it 'displays the all 4 key information ' do
    unassigned_case = double CaseDecorator,
                   message: "This is a request for information"


    render partial: 'cases/case_request.html.slim',
           locals:{ case_details: unassigned_case}

    partial = case_request_section(rendered)

    expect(partial.message.text).to eq unassigned_case.message

  end

end
