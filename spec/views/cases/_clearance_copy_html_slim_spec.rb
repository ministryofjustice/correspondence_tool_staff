require 'rails_helper'

describe 'cases/clearance_copy.html.slim', type: :view do
  let(:kase)      { create :accepted_case, :flagged, subject: "Optimism – is a lack of information." }
  let(:nsi)      { NextStepInfo.new(kase, 'upload') }
  let(:partial) do
    render partial: 'cases/clearance_copy', locals: { nsi: nsi }
    clearance_copy_section(rendered)
  end

  it 'displays the current action and case status' do
    expect(partial.action.text)
        .to eq "You are uploading responses to the case: Optimism – is a lack of information."
  end

  it 'displays the team' do
    expect(partial.expectations.team.text)
        .to eq kase.responding_team.name
  end

  it 'displays the status' do
    expect(partial.expectations.status.text)
        .to eq "awaiting dispatch"
  end
end
