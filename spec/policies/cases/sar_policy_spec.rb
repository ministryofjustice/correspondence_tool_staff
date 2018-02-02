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

  let(:unassigned_case) { create :sar_case }

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
          unassigned_case.add_linked_case kase
          unassigned_case.save!
        end
      end

      it { should     permit(responder,             unassigned_case) }
      it { should_not permit(disclosure_specialist, unassigned_case) }
    end
  end
end
