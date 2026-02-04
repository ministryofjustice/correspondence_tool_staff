require "rails_helper"

describe Case::SARPolicy do
  subject { described_class }

  # Teams
  let(:managing_team)         { find_or_create :team_dacu }
  let(:responding_team)       { create :responding_team }
  let(:team_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { team_disclosure.approvers.first }

  let(:unassigned_case)       { create :sar_case }
  let(:other_managing_team)   { create :managing_team }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:admin_team)            { find_or_create :team_for_admin_users }

  # Users
  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }
  let(:branston_user)         { find_or_create :branston_user }

  # Cases
  let(:non_trigger_sar_case) do
    create :sar_case,
           managing_team:,
           responding_team:
  end

  let(:trigger_sar_case) do
    create :sar_case,
           :flagged,
           managing_team:,
           responding_team:
  end

  let(:ot_sar_case) do
    create :overturned_ico_sar,
           managing_team:,
           responding_team:
  end

  let(:trigger_ot_sar_case) do
    create :overturned_ico_sar,
           :flagged_accepted,
           :dacu_disclosure,
           managing_team:,
           responding_team:
  end

  let(:approved_sar) do
    create :approved_sar,
           managing_team:,
           responding_team:
  end

  let(:extended_sar_case) do
    create :approved_sar,
           :extended_deadline_sar,
           :flagged_accepted,
           :dacu_disclosure,
           manager:,
           approver: disclosure_specialist,
           managing_team:
  end

  let(:closed_sar_case) do
    create :offender_sar_case,
           :closed,
           managing_team:,
           responding_team:
  end

  after do |example|
    if example.exception
      failed_checks = begin
        described_class.failed_checks
      rescue StandardError
        []
      end
      Rails.logger.debug "Failed CasePolicy checks: #{failed_checks.map(&:first).map(&:to_s).join(', ')}"
    end
  end

  permissions :show? do
    context "when unassigned case" do
      it { is_expected.to     permit(manager,               unassigned_case) }
      it { is_expected.not_to permit(responder,             unassigned_case) }
      it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    end

    context "when linked case" do
      before do
        create(:closed_sar, responding_team:).tap do |kase|
          unassigned_case.related_cases << kase
        end
      end

      it { is_expected.not_to permit(responder,             unassigned_case) }
      it { is_expected.not_to permit(disclosure_specialist, unassigned_case) }
    end
  end

  context "when non trigger non offender (London) SAR case" do
    permissions :new_case_link? do
      it { is_expected.to     permit(manager,             non_trigger_sar_case) }
      it { is_expected.not_to permit(other_manager,       non_trigger_sar_case) }
      it { is_expected.not_to permit(responder,           non_trigger_sar_case) }
      it { is_expected.not_to permit(press_officer,       non_trigger_sar_case) }
      it { is_expected.not_to permit(private_officer,     non_trigger_sar_case) }
      it { is_expected.not_to permit(disclosure_approver, non_trigger_sar_case) }
    end
  end

  permissions :can_request_further_clearance? do
    it { is_expected.to     permit(manager,             non_trigger_sar_case) }
    it { is_expected.not_to permit(manager,             trigger_sar_case)     }
    it { is_expected.to     permit(manager,             ot_sar_case)          }
    it { is_expected.not_to permit(manager,             trigger_ot_sar_case)  }
  end

  # rubocop:disable RSpec/RepeatedExample
  context "when SAR deadline extension" do
    permissions :extend_sar_deadline? do
      it { is_expected.not_to permit(responder,             approved_sar) }
      it { is_expected.to     permit(manager,               approved_sar) }
      it { is_expected.to     permit(disclosure_approver,   approved_sar) }

      it { is_expected.not_to permit(responder,             non_trigger_sar_case) }
      it { is_expected.not_to permit(manager,               non_trigger_sar_case) }
      it { is_expected.not_to permit(disclosure_approver,   non_trigger_sar_case) }
    end

    permissions :remove_sar_deadline_extension? do
      it { is_expected.not_to permit(responder,             approved_sar) }
      it { is_expected.not_to permit(manager,               approved_sar) }
      it { is_expected.not_to permit(disclosure_approver,   approved_sar) }

      it { is_expected.not_to permit(responder,             extended_sar_case) }
      it { is_expected.to     permit(manager,               extended_sar_case) }
      it { is_expected.to     permit(disclosure_approver,   extended_sar_case) }
    end
  end
  # rubocop:enable RSpec/RepeatedExample

  permissions :can_perform_retention_actions? do
    context "when can see the case" do
      let(:team_admin_user) { find_or_create :branston_user }

      before do
        tur = TeamsUsersRole.new(
          team_id: admin_team.id,
          user_id: team_admin_user.id,
          role: "team_admin",
        )

        team_admin_user.team_roles << tur
      end

      context "and the case is closed" do
        it { is_expected.to permit(team_admin_user, closed_sar_case) }
        it { is_expected.not_to permit(responder, closed_sar_case) }
      end

      context "and the case is not closed" do
        it { is_expected.not_to permit(team_admin_user, approved_sar) }
        it { is_expected.not_to permit(responder, approved_sar) }
      end
    end

    context "when cannot see the case" do
      it { is_expected.not_to permit(branston_user, approved_sar) }
      it { is_expected.not_to permit(responder, approved_sar) }
    end
  end
end
