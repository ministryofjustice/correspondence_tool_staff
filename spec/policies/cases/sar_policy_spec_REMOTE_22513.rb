require 'rails_helper'

describe Case::SARPolicy do

  subject { described_class }

  # Teams
  let(:managing_team)         { find_or_create :team_dacu }
  let(:other_managing_team)   { create :managing_team }
  let(:responding_team)       { create :responding_team }
  let(:dacu_disclosure)      { find_or_create :team_dacu_disclosure }

  # Users
  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }

  # Cases
  let(:non_trigger_sar_case)  { create :sar_case,
                                       managing_team: managing_team,
                                       responding_team: responding_team}


  after(:each) do |example|
    if example.exception
      failed_checks = described_class.failed_checks rescue []
      puts "Failed CasePolicy checks: " +
               failed_checks.map(&:first).map(&:to_s).join(', ')
    end
  end


  context 'Non trigger non offender (London) SAR case' do

    permissions :new_case_link? do
      it { should     permit(manager,             non_trigger_sar_case) }
      it { should_not permit(other_manager,       non_trigger_sar_case) }
      it { should_not permit(responder,           non_trigger_sar_case) }
      it { should_not permit(press_officer,       non_trigger_sar_case) }
      it { should_not permit(private_officer,     non_trigger_sar_case) }
      it { should_not permit(disclosure_approver, non_trigger_sar_case) }
    end
  end
end
