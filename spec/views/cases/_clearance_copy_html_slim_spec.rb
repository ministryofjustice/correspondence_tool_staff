require 'rails_helper'

describe 'cases/clearance_copy.html.slim', type: :view do
  let(:kase)      { double CaseDecorator,
                               subject: "Optimism – is a lack of information." }
  let(:partial) do
    render partial: 'cases/clearance_copy',
           locals: { case_details: kase,
                     status: "Ready to send",
                     team: "DACU",
                     action: "clearing"}

    clearance_copy_section(rendered)
  end

  it 'displays the current action and case status' do
    expect(partial.action.text)
        .to eq "You are clearing the response to: #{kase.subject}"
  end

  it 'displays the team' do
    expect(partial.expectations.team.text)
        .to eq "DACU"
  end

  it 'displays the status' do
    expect(partial.expectations.status.text)
        .to eq "Ready to send"
  end
end
