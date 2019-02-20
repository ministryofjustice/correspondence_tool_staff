require "rails_helper"

describe Case::SARPolicy do
  subject { described_class }

  # Teams
  let(:managing_team)         { find_or_create :team_dacu }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:team_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { team_disclosure.approvers.first }

  let(:unassigned_case)       { create :sar_case }
  let(:other_managing_team)   { create :managing_team }
  let(:responding_team)       { create :responding_team }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }

  # Users
  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }

  # Cases
  let(:non_trigger_sar_case)   { create :sar_case,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  let(:trigger_sar_case)       { create :sar_case,
                                        :flagged,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  let(:ot_sar_case)            { create :overturned_ico_sar,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  let(:trigger_ot_sar_case)    { create :overturned_ico_sar,
                                        :flagged_accepted,
                                        :dacu_disclosure,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  let(:approved_sar)           { create :approved_sar,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  let(:extended_sar_case)      { create :extended_deadline_sar,
                                        :flagged_accepted,
                                        :dacu_disclosure,
                                        managing_team: managing_team,
                                        responding_team: responding_team }

  after(:each) do |example|
    if example.exception
      failed_checks = described_class.failed_checks rescue []
      puts "Failed CasePolicy checks: " +
           failed_checks.map(&:first).map(&:to_s).join(', ')
    end
  end

  permissions :show? do
    context 'unassigned case' do
      it { should     permit(manager,               unassigned_case) }
      it { should_not permit(responder,             unassigned_case) }
      it { should_not permit(disclosure_specialist, unassigned_case) }
    end

    context 'linked case' do
      let!(:linked_case) do
        create(:closed_sar, responding_team: responding_team).tap do |kase|
          unassigned_case.related_cases << kase
        end
      end

      it { should_not permit(responder,             unassigned_case) }
      it { should_not permit(disclosure_specialist, unassigned_case) }
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

  permissions :can_request_further_clearance? do
    it { should     permit(manager,             non_trigger_sar_case) }
    it { should_not permit(manager,             trigger_sar_case)     }
    it { should     permit(manager,             ot_sar_case)          }
    it { should_not permit(manager,             trigger_ot_sar_case)  }
  end

  context 'SAR deadline extension' do
    permissions :extend_sar_deadline? do
      it { should_not permit(responder,             approved_sar) }
      it { should     permit(manager,               approved_sar) }
      it { should     permit(disclosure_approver,   approved_sar) }

      it { should_not permit(responder,             non_trigger_sar_case) }
      it { should_not permit(manager,               non_trigger_sar_case) }
      it { should_not permit(disclosure_approver,   non_trigger_sar_case) }
    end

    permissions :remove_sar_deadline_extension? do
      it { should_not permit(responder,             approved_sar) }
      it { should_not permit(manager,               approved_sar) }
      it { should_not permit(disclosure_approver,   approved_sar) }

      it { should_not permit(responder,             extended_sar_case) }
      it { should     permit(manager,               extended_sar_case) }
      it { should     permit(disclosure_approver,   extended_sar_case) }
    end
  end
end
