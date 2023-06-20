# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

require "rails_helper"

RSpec.describe BusinessUnit, type: :model do
  let(:foi)                 { CorrespondenceType.foi }
  let(:sar)                 { CorrespondenceType.sar }
  let(:foi_responding_team) { find_or_create :foi_responding_team }
  let(:sar_responding_team) { find_or_create :sar_responding_team }

  it "can be created" do
    bu = described_class.create! name: "Busy Units",
                                 email: "busy.units@localhost",
                                 parent_id: 1,
                                 role: "responder",
                                 correspondence_type_ids: [foi.id]
    expect(bu).to be_valid
  end

  it { is_expected.to validate_presence_of(:parent_id) }

  it { is_expected.to belong_to(:directorate).with_foreign_key(:parent_id) }

  it { is_expected.to have_one(:business_group).through(:directorate) }

  it {
    expect(subject).to have_many(:user_roles)
                .class_name("TeamsUsersRole")
  }

  it { is_expected.to have_many(:users).through(:user_roles) }

  it {
    expect(subject).to have_many(:manager_user_roles)
                .class_name("TeamsUsersRole")
                .with_foreign_key("team_id")
  }

  it { is_expected.to have_many(:managers).through(:manager_user_roles) }

  it {
    expect(subject).to have_many(:responder_user_roles)
                 .class_name("TeamsUsersRole")
                 .with_foreign_key("team_id")
  }

  it { is_expected.to have_many(:responders).through(:responder_user_roles) }

  it {
    expect(subject).to have_many(:approver_user_roles)
                .class_name("TeamsUsersRole")
                .with_foreign_key("team_id")
  }

  it { is_expected.to have_many(:approvers).through(:approver_user_roles) }

  describe "cases scope" do
    before(:all) do
      @team_1 = create :responding_team
      @team_2 = create :responding_team

      @unassigned_case                  = create :case, name: "unassigned"
      @t1_assigned_case                 = create :assigned_case, responding_team: @team_1, name: "t1-assigned"
      @t1_accepted_case                 = create :accepted_case, responding_team: @team_1, name: "t1-accepted"
      @t1_rejected_case                 = create :rejected_case,
                                                 responding_team: @team_1,
                                                 name: "t1-rejected"
      @t1_pending_dacu_clearance_case   = create :pending_dacu_clearance_case, responding_team: @team_1, name: "t1-pending-dacu"
      @t1_responded_case                = create :responded_case, responding_team: @team_1, name: "t1-responded"
      @t1_closed_case                   = create :closed_case, responding_team: @team_1, name: "t1-closed"

      @t2_assigned_case                 = create :assigned_case, responding_team: @team_2, name: "t2-assigned"
      @t2_accepted_case                 = create :accepted_case, responding_team: @team_2, name: "t2-accepted"
      @t2_rejected_case                 = create :rejected_case, responding_team: @team_2, name: "t2-rejected"
      @t2_pending_dacu_clearance_case   = create :pending_dacu_clearance_case, responding_team: @team_2, name: "t2-pending-dacu"
      @t2_responded_case                = create :responded_case, responding_team: @team_2, name: "t2-responded"
      @t2_closed_case                   = create :closed_case, responding_team: @team_2, name: "t2-closed"
    end

    after(:all) { DbHousekeeping.clean }

    describe "scope cases" do
      it "returns all cases allocated to the team including rejected and closed" do
        expect(@team_1.cases).to match_array([
          @t1_assigned_case,
          @t1_accepted_case,
          @t1_rejected_case,
          @t1_pending_dacu_clearance_case,
          @t1_responded_case,
          @t1_closed_case,
        ])
      end
    end

    describe "scope pending_accepted_cases" do
      it "does not return responded or closed cases" do
        expect(@team_1.open_cases).to match_array([
          @t1_assigned_case,
          @t1_accepted_case,
          @t1_pending_dacu_clearance_case,
        ])
      end
    end
  end

  context "when multiple teams created" do
    let(:managing_team)       { find_or_create :team_dacu }
    let(:branston_team)       { find_or_create :team_branston }
    let(:approving_team)      { find_or_create :approving_team }

    describe "managing scope" do
      it "returns only managing teams" do
        expect(described_class.managing).to match_array [managing_team]
      end
    end

    describe "responding scope" do
      it "returns only responding teams" do
        expect(described_class.responding).to match_array [
          foi_responding_team,
          sar_responding_team,
          branston_team,
        ]
      end
    end

    describe "approving scope" do
      it "returns only approving teams" do
        expect(described_class.approving).to match_array [
          described_class.press_office,
          described_class.private_office,
          described_class.dacu_disclosure,
          approving_team,
        ]
      end
    end

    describe "active scope" do
      it "returns only teams that are not deactivated" do
        expect(described_class.responding.active.count).to eq 3
        foi_responding_team.update_attribute(:deleted_at, Time.zone.now)
        expect(described_class.responding.active).to match_array [
          sar_responding_team,
          branston_team,
        ]
      end
    end
  end

  it "has a working factory" do
    expect(create(:business_unit)).to be_valid
  end

  context "when specific team finding and querying" do
    before(:all) do
      @press_office_team = find_or_create :team_press_office
      @private_office_team = find_or_create :team_private_office
      @dacu_disclosure_team = find_or_create :team_dacu_disclosure
      @dacu_bmt_team = find_or_create :team_dacu
    end

    after(:all) do
      DbHousekeeping.clean
    end

    describe ".dacu_disclosure" do
      it "finds the DACU Disclosure team" do
        expect(described_class.dacu_disclosure).to eq @dacu_disclosure_team
      end
    end

    describe "#dacu_disclosure?" do
      it "returns true if dacu disclosure" do
        expect(@dacu_disclosure_team.dacu_disclosure?).to be true
      end
    end

    describe ".dacu_bmt" do
      it "finds the DACU BMT team" do
        expect(described_class.dacu_bmt).to eq @dacu_bmt_team
      end
    end

    describe "#dacu_bmt?" do
      it "returns true if dacu bmt" do
        expect(@dacu_bmt_team.dacu_bmt?).to be true
      end
    end

    describe ".press_office" do
      it "finds the Press Office team" do
        expect(described_class.press_office).to eq @press_office_team
      end
    end

    describe "#press_office?" do
      it "returns true if press office team" do
        expect(@press_office_team.press_office?).to be true
      end

      it "returns false if not press office team" do
        expect(@dacu_disclosure_team.press_office?).to be false
      end
    end

    describe ".private_office" do
      it "finds the Private Office team" do
        expect(described_class.private_office).to eq @private_office_team
      end
    end

    describe "#private_office?" do
      it "returns true if private office team" do
        expect(@private_office_team.private_office?).to be true
      end

      it "returns false if not private office team" do
        expect(@dacu_disclosure_team.private_office?).to be false
      end
    end
  end

  describe ".responding_for_correspondence_type" do
    before do
      @bu_foi = create :business_unit, correspondence_type_ids: [foi.id]
      @bu_sar = create :business_unit, correspondence_type_ids: [sar.id]
    end

    it "only returns business units with reponding roles for the FOIs" do
      business_units = described_class.responding_for_correspondence_type(foi)
      expect(business_units).to match_array [foi_responding_team,
                                             sar_responding_team,
                                             @bu_foi]
    end

    it "only returns business units with reponding roles for the SARs" do
      business_units = described_class.responding_for_correspondence_type(sar)
      expect(business_units).to match_array [foi_responding_team,
                                             sar_responding_team,
                                             @bu_sar]
    end
  end

  describe "#correspondence_types" do
    let(:foi) { create :foi_correspondence_type }
    let(:sar) { create :sar_correspondence_type }
    let(:dir) { create :directorate }

    it { is_expected.to have_many(:correspondence_types).through(:correspondence_type_roles) }

    it "removes existing correspondence type roles when assigning" do
      bu = described_class.create! name: "correspondence_type test",
                                   role: "manager",
                                   parent: dir,
                                   correspondence_types: [foi]
      expect(bu.correspondence_types).to eq [foi]
      bu.correspondence_types = [sar]
      bu.reload
      expect(bu.correspondence_types).to eq [sar]
    end
  end

  describe "#correspondence_type_ids" do
    it "returns an array of correspondence_type ids" do
      @bu = create :business_unit, correspondence_type_ids: [sar.id, foi.id]
      expect(@bu.correspondence_type_ids).to match_array([sar.id, foi.id])
    end
  end

  describe "#correspondence_type_ids=" do
    let(:dir) { create :directorate }
    let(:foi) { create :foi_correspondence_type }
    let(:sar) { create :sar_correspondence_type }
    let(:gq)  { create :gq_correspondence_type }

    it "adds new team correspondence_type role records" do
      bu = described_class.new(name: "bu1", parent: dir, role: "manager")
      expect(bu.correspondence_type_roles).to be_empty
      bu.correspondence_type_ids = [foi.id, sar.id]
      bu.save!
      expect(bu.correspondence_type_roles.size).to eq 2
      foi_tcr = bu.correspondence_type_roles.detect { |r| r.correspondence_type_id == foi.id }
      sar_tcr = bu.correspondence_type_roles.detect { |r| r.correspondence_type_id == sar.id }
      expect(foi_tcr).to match_tcr_attrs(:foi, :view, :edit, :manage)
      expect(sar_tcr).to match_tcr_attrs(:sar, :view, :edit, :manage)
    end

    it "deletes unused and adds new team correpondence_types" do
      bu = create :business_unit, correspondence_types: [foi, sar]
      expect(bu.correspondence_types.map(&:abbreviation))
        .to match_array %w[FOI SAR]
      bu.correspondence_type_ids = [sar.id, gq.id]
      expect(bu.reload.correspondence_types.map(&:abbreviation))
        .to match_array %w[SAR GQ]
    end
  end

  describe "#update search index" do
    context "when new business unit" do
      it "queues a job to update the search index" do
        expect {
          create :responding_team
        }.to have_enqueued_job(SearchIndexBuNameUpdaterJob)
      end
    end

    context "when update existing business unit" do
      before { @business_unit = create :responding_team }

      context "and name is changed" do
        it "queues a job to update the search index" do
          expect {
            @business_unit.update(name: "my new business unit")
          }.to have_enqueued_job(SearchIndexBuNameUpdaterJob)
        end
      end

      context "and name is not changed" do
        it "does not queue a job to update the search index" do
          expect {
            @business_unit.update(email: "my_new_email@moj.gov.uk")
          }.not_to have_enqueued_job(SearchIndexBuNameUpdaterJob)
        end
      end
    end
  end

  describe "#previous_teams" do
    context "when a team has never moved" do
      it "returns empty array" do
        current_team = create :business_unit
        expect(current_team.previous_teams).to be_empty
      end
    end

    context "when a team has been moved once" do
      let(:original_dir) { find_or_create :directorate }
      let(:target_dir) { find_or_create :directorate }

      let(:previous_team) do
        find_or_create(
          :business_unit,
          directorate: original_dir,
        )
      end

      it "returns team moved-from" do
        service = TeamMoveService.new(previous_team, target_dir)
        service.call
        current_team = service.new_team
        expect(current_team.previous_teams).to match_array [previous_team]
      end
    end

    context "when a team has been moved twice" do
      let(:original_dir) { find_or_create :directorate }
      let(:first_target_dir) { find_or_create :directorate }
      let(:second_target_dir) { find_or_create :directorate }
      let(:business_unit_to_move) do
        find_or_create(
          :business_unit,
          directorate: original_dir,
        )
      end

      it "tracks all history" do
        first_team = business_unit_to_move
        service = TeamMoveService.new(first_team, first_target_dir)
        service.call
        second_team = service.new_team

        # pause momentarily to let the database catch up
        sleep 1

        service = TeamMoveService.new(second_team, second_target_dir)
        service.call

        third_team = service.new_team

        expect(third_team.previous_teams).to match_array [first_team, second_team]
      end
    end

    context "when a team has been joined" do
      let(:original_dir) { find_or_create :directorate }
      let(:joining_team) { create(:responding_team, name: "Joining Team") }
      let(:original_target_team) { create(:responding_team, name: "Target Team") }
      let(:first_target_dir) { find_or_create :directorate }
      let(:second_target_dir) { find_or_create :directorate }
      let(:business_unit_to_move) do
        find_or_create(
          :business_unit,
          directorate: original_dir,
        )
      end
      let(:business_unit_for_history) do
        find_or_create(
          :business_unit,
          directorate: original_dir,
        )
      end
      let(:responder) { create(:foi_responder, responding_teams: [business_unit_for_history]) }
      let(:responder) { create(:foi_responder, responding_teams: [business_unit]) }
      let(:business_unit) do
        find_or_create(
          :business_unit,
          name: "Business Unit name",
          directorate: original_dir,
          code: "ABC",
        )
      end
      let(:params) do
        ActiveSupport::HashWithIndifferentAccess.new(
          {
            "full_name" => "Bob Dunnit",
            "email" => "bd@moj.com",
          },
        )
      end

      let(:params_joe) do
        ActiveSupport::HashWithIndifferentAccess.new(
          {
            "full_name" => "Joe Didit",
            "email" => "jd@moj.com",
          },
        )
      end

      let(:new_user_service) { UserCreationService.new(team: business_unit, params:) }

      let(:original_target_team) { create(:responding_team, name: "Target Team") }
      let(:joining_team) { create(:responding_team, name: "Joining Team") }

      it "tracks all ancestors of team" do
        first_team = business_unit_to_move
        service = TeamMoveService.new(first_team, first_target_dir)
        service.call
        second_team = service.new_team

        # pause momentarily to let the database catch up
        sleep 1

        service = TeamMoveService.new(second_team, second_target_dir)
        service.call

        third_team = service.new_team
        # create another team, with history into third team
        fourth_team = business_unit_for_history
        service = TeamMoveService.new(fourth_team, first_target_dir)
        service.call
        fifth_team = service.new_team

        service = TeamJoinService.new(fifth_team, third_team)
        service.call
        expect(third_team.previous_teams).to match_array [first_team, second_team, fourth_team, fifth_team]
      end

      it "assigns current and historic user roles for teams with history" do
        joining_team_user = joining_team.users.first
        original_target_team_user = original_target_team.users.first

        service = TeamMoveService.new(original_target_team, first_target_dir)
        service.call
        target_team = service.new_team

        service = TeamJoinService.new(joining_team, target_team)
        service.call

        expect(target_team.reload.responders).to match_array [joining_team_user, original_target_team_user]

        expect(original_target_team_user.reload.teams).to match_array [
          original_target_team, target_team, joining_team
        ]

        expect(joining_team_user.reload.teams).to match_array [
          original_target_team, target_team, joining_team
        ]

        historic_teams = target_team.reload.historic_user_roles.collect(&:team).uniq
        expect(historic_teams).to match_array [original_target_team, joining_team]
      end
    end
  end
end
