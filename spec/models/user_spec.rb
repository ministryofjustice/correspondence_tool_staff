# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#  deleted_at             :datetime
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { create(:user) }

  let(:offender_sar)        { create(:offender_sar_correspondence_type) }
  let(:overturned_foi)      { create(:overturned_foi_correspondence_type) }
  let(:overturned_sar)      { create(:overturned_sar_correspondence_type) }
  let(:sar_internal_review) { create(:sar_internal_review_correspondence_type) }
  let(:sar)                 { create(:sar_correspondence_type) }
  let(:ico)                 { create(:ico_correspondence_type) }
  let(:foi)                 { create(:foi_correspondence_type) }
  let(:deactivated_user)    { create :deactivated_user }
  let(:press_officer)       { find_or_create :press_officer }
  let(:approver)            { create :approver }
  let(:responder)           { create :responder }
  let(:manager)             { create :manager }
  let(:system_admin)        { described_class.system_admin }

  it { is_expected.to have_many(:assignments) }
  it { is_expected.to have_many(:cases)       }
  it { is_expected.to validate_presence_of(:full_name) }
  it { is_expected.to have_many(:team_roles).class_name("TeamsUsersRole") }
  it { is_expected.to have_many(:teams).through(:team_roles) }
  it { is_expected.to have_many(:managing_team_roles).class_name("TeamsUsersRole") }
  it { is_expected.to have_many(:responding_team_roles).class_name("TeamsUsersRole") }
  it { is_expected.to have_one(:approving_team_roles).class_name("TeamsUsersRole") }
  it { is_expected.to have_many(:managing_teams).through(:managing_team_roles) }
  it { is_expected.to have_many(:responding_teams).through(:responding_team_roles) }
  it { is_expected.to have_one(:approving_team).through(:approving_team_roles) }

  describe ".system_admin" do
    context "when system admin does not exist" do
      it "creates a new user" do
        expect {
          described_class.system_admin
        }.to change(described_class, :count).by 1
      end
    end

    context "when system admin already exists" do
      it "does not create a new user" do
        described_class.system_admin

        expect {
          described_class.system_admin
        }.not_to change(described_class, :count)
      end
    end

    it "the returns a user with the expected name" do
      expect(described_class.system_admin.full_name).to eq "System update"
    end

    it "the returns a user with the expected roles" do
      expect(described_class.system_admin.roles).to eq %w[admin responder]
    end
  end

  describe "#system_admin?" do
    it "returns true for a system admin" do
      expect(system_admin.system_admin?).to be true
    end

    it "returns false for a manager" do
      expect(manager.system_admin?).to be false
    end

    it "returns false for a responder" do
      expect(responder.system_admin?).to be false
    end

    it "returns false for an approver" do
      expect(approver.system_admin?).to be false
    end
  end

  describe "#manager?" do
    it "returns true for a manager" do
      expect(manager.manager?).to be true
    end

    it "returns false for a responder" do
      expect(responder.manager?).to be false
    end

    it "returns false for an approver" do
      expect(approver.manager?).to be false
    end
  end

  describe "#responder?" do
    it "returns false for a manager" do
      expect(manager.responder?).to be false
    end

    it "returns true for a responder" do
      expect(responder.responder?).to be true
    end

    it "returns false for an approver" do
      expect(approver.responder?).to be false
    end
  end

  describe "#responder_only?" do
    it "returns true for a user who is a reponder and not a manager or approver" do
      expect(responder.responder_only?).to be true
    end

    it "returns false for a responder who is also a manager and approver" do
      user = create :approver_responder_manager
      expect(user.responder_only?).to be false
    end

    it "returns false for a responder who is also an approver" do
      user = create :approver_responder
      expect(user.responder_only?).to be false
    end

    it "returns false for managers" do
      expect(manager.responder_only?).to be false
    end

    it "returns false for approvers" do
      expect(approver.responder_only?).to be false
    end
  end

  describe "#approver?" do
    it "returns false for a manager" do
      expect(manager.approver?).to be false
    end

    it "returns false for a responder" do
      expect(responder.approver?).to be false
    end

    it "returns true for an approver" do
      expect(approver.approver?).to be true
    end
  end

  describe "has_one: approving_team" do
    it "returns the first active approving team" do
      current_approving_team = approver.approving_team
      new_team = create :business_unit, correspondence_type_ids: [foi.id]
      approver.team_roles << TeamsUsersRole.new(team: new_team, role: "approver")
      approver.reload
      current_approving_team.deleted_at = Time.zone.now
      current_approving_team.save!
      approver.reload
      expect(approver.approving_team).to eq new_team
    end
  end

  describe "has_many: managing_teams" do
    it "returns active managing teams" do
      current_managing_team = manager.managing_teams.first
      new_team = create :managing_team, correspondence_type_ids: [foi.id]
      manager.team_roles << TeamsUsersRole.new(team: new_team, role: "manager")
      manager.reload
      current_managing_team.deleted_at = Time.zone.now
      current_managing_team.save!
      manager.reload
      expect(manager.managing_teams.first).to eq new_team
    end
  end

  describe "#roles" do
    it "returns the roles given users" do
      expect(manager.roles).to eq %w[manager]
    end
  end

  describe "press_officer?" do
    it "returns true if user is in press office team" do
      expect(press_officer.press_officer?).to be true
    end

    it "returns false if the user is not in the press office" do
      find_or_create :team_press_office
      expect(approver.press_officer?).not_to be true
    end
  end

  describe "#case_team" do
    let(:kase) { create(:pending_dacu_clearance_case) }
    let(:new_team) { create(:business_unit, correspondence_type_ids: [foi.id]) }

    context "when user is in one of the teams associated with the case" do
      it "returns the team link to user and case both" do
        check_user = kase.responder
        check_user.team_roles << TeamsUsersRole.new(team: new_team, role: "approver")
        check_user.reload
        expect(check_user.case_team(kase)).to eq kase.responding_team
      end
    end

    context "when user is not in the teams associated with the case" do
      it "returns the team only link to the user " do
        check_user = create(:user)
        check_user.team_roles << TeamsUsersRole.new(team: new_team, role: "approver")
        check_user.reload
        expect(check_user.case_team(kase)).to eq new_team
      end
    end

    context "when user is the system admin" do
      it "returns a team from the case" do
        check_user = system_admin
        expect(check_user.case_team(kase)).to be_in kase.teams
      end
    end
  end

  describe "#case_team_for_event" do
    context "when user is in one of the teams associated with the case" do
      it "returns the team link to user and case both" do
        kase = create :accepted_case
        check_user = kase.responder
        check_user.team_roles << TeamsUsersRole.new(team: kase.managing_team, role: "manager")
        check_user.reload
        expect(check_user.case_team_for_event(kase, "add_responses")).to eq kase.responding_team
      end
    end

    context "when user is in multiple teams associated with the case" do
      it "returns the team link having highest authority to user and case both" do
        kase = create :pending_dacu_clearance_case
        check_user = kase.responder
        approving_team = kase.approving_teams.first
        check_user.team_roles << TeamsUsersRole.new(team: kase.approving_teams.first, role: "approver")
        check_user.reload
        expect(check_user.teams_for_case(kase)).to match_array [approving_team, kase.responding_team]
        expect(check_user.case_team_for_event(kase, "reassign_user")).to eq approving_team
      end

      it "returns the team link having highest authority not including the team rejecting the case" do
        kase = create :accepted_case
        check_user = kase.responder
        another_team = create :business_unit, name: "testing team"

        responding_assignment = Assignment.new(
          case_id: kase.id,
          team: another_team,
          user: check_user,
          state: "rejected",
          role: "responding",
          reasons_for_rejection: "testing",
        )
        responding_assignment.save!
        check_user.team_roles << TeamsUsersRole.new(team: kase.managing_team, role: "manager")
        check_user.team_roles << TeamsUsersRole.new(team: another_team, role: "responder")
        check_user.reload
        kase.reload

        expect(check_user.teams_for_case(kase)).to match_array [kase.managing_team, another_team, kase.responding_team]
        expect(check_user.case_team_for_event(kase, "add_responses")).to eq kase.responding_team
      end
    end
  end

  describe "#roles_for_case" do
    context "when user has just one role for a case" do
      it "returns an array of one role" do
        kase = create :pending_dacu_clearance_case
        responder = kase.responder
        expect(responder.roles_for_case(kase)).to eq %w[responder]
      end
    end

    context "when user has many roles for a case" do
      it "returns an array of all roles" do
        user = create :manager_approver, managing_teams: [find_or_create(:team_disclosure_bmt)]
        kase = create :pending_dacu_clearance_case, approver: user, manager: user
        expect(user.roles_for_case(kase)).to match_array(%w[approver manager])
      end
    end

    context "when user has no roles for a case" do
      it "returns an empty array" do
        kase = create :pending_dacu_clearance_case
        user = create :user
        expect(user.roles_for_case(kase)).to be_empty
      end
    end
  end

  describe "#soft_delete" do
    it "updates the deleted_at attribute" do
      user.soft_delete
      expect(user.deleted_at).not_to be nil
    end
  end

  describe "#active_for_authentication" do
    it "return true for active user" do
      expect(user.active_for_authentication?).to be true
    end

    it "returns false for deactivated user" do
      user.soft_delete
      expect(user.active_for_authentication?).to be false
    end
  end

  describe "#has_live_cases_for_team?" do
    let(:closed_case)     { create :closed_case }
    let(:responded_case)  { create :responded_case }
    let(:assigned_case)   { create :assigned_case }
    let(:responder)       { responding_team.responders.first }
    let(:assignment)      { assigned_case.responder_assignment }
    let(:responding_team) { assignment.team }

    it "returns false for a user with no assignments" do
      expect(user.has_live_cases_for_team?(responding_team)).to be false
    end

    it "returns true for a user with an open case" do
      assignment = assigned_case.responder_assignment
      assignment.accept(responder)
      expect(responder.has_live_cases_for_team?(assignment.team)).to be true
    end

    it "returns false for a user with a closed case" do
      assignment = closed_case.responder_assignment
      expect(assignment.user.has_live_cases_for_team?(assignment.team)).to be false
    end

    it "returns false for a user with a responded case" do
      assignment = responded_case.responder_assignment
      expect(assignment.user.has_live_cases_for_team?(assignment.team)).to be false
    end
  end

  describe "#multiple_team_member?" do
    let(:foi_responding_team) { find_or_create :foi_responding_team }

    it "returns false for a user with one team" do
      expect(responder.multiple_team_member?).to be false
    end

    it "returns true for a user with multiple teams" do
      expect(responder.multiple_team_member?).to be false
      responder.team_roles << TeamsUsersRole.new(team: foi_responding_team, role: "responder")
      expect(responder.multiple_team_member?).to be true
    end
  end

  describe "#permitted_correspondence_types" do
    it "returns any correspondence types associated with users teams" do
      expect(manager.permitted_correspondence_types)
        .to match_array([foi, ico, sar, sar_internal_review, overturned_foi, overturned_sar])
    end
  end

  describe "paper_trail versions", versioning: true do
    it "has versions" do
      expect(user).to be_versioned
    end

    context "when creating" do
      it "updates versions" do
        expect(responder.versions.length).to eq 1
        expect(responder.versions.last.event).to eq "create"
      end
    end

    context "when updating" do
      it "updates versions" do
        expect { responder.update!(full_name: "Namerson") }.to change(responder.versions, :count).by 1
        expect(responder.versions.last.event).to eq "update"
      end
    end
  end

  context "with password setting" do
    context "and in blacklist" do
      it "errors" do
        user.password = "qwertyuiop"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to eq ["too easily guessable. Please use another password at least 10 characters long."]
      end
    end

    context "and too short" do
      it "errrors" do
        user.password = "abc"
        expect(user).not_to be_valid
        expect(user.errors[:password]).to eq ["is too short (minimum is 10 characters)"]
      end
    end

    context "and long non-blackilsted password" do
      it "does not error and changes the encrypted password" do
        original_encrypted_password = user.encrypted_password
        user.password = SecureRandom.random_number(36**13).to_s(36)
        expect(user).to be_valid
        expect(user.encrypted_password).not_to eq original_encrypted_password
      end
    end
  end

  describe "#other_teams_names" do
    let(:user)      { create :responder, responding_teams: [team1, team2, team3] }
    let(:team1)     { create :responding_team }
    let(:team2)     { create :responding_team }
    let(:team3)     { create :responding_team }

    it "prints out the other teams" do
      team1_other_team_names = user.other_teams_names(team1)
      expect(team1_other_team_names).to include(team2.name, team3.name)
      expect(team1_other_team_names).not_to include(team1.name)
    end
  end

  describe "warehousable" do
    let(:user) { create(:user) }

    before do
      user.reload
    end

    context "when updating team name" do
      it "creates sync job" do
        user.full_name = "new name"
        expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("User", user.id)
        user.save!
      end
    end

    context "when updating another attribute" do
      it "doesn't create sync job" do
        user.email = "new@email.com"
        expect(::Warehouse::CaseSyncJob).not_to receive(:perform_later)
        user.save!
      end
    end
  end
end
