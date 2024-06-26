require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
RSpec.describe Case::Base, type: :model do # rubocop:disable RSpec/FilePath
  let(:responding_team) { find_or_create :foi_responding_team }
  let(:responder)       { responding_team.responders.first }
  let(:co_responder)    do
    create(:responder,
           responding_teams: [responding_team])
  end
  let(:other_responding_team) { create(:responding_team) }
  let(:assigned_case) do
    create :assigned_case,
           responding_team:
  end
  let(:accepted_case) do
    create :accepted_case,
           responding_team:,
           responder:
  end
  let(:accepted_sar) do
    create :accepted_sar,
           responding_team:,
           responder:
  end

  context "when flagged for approval scopes" do
    before(:all) do
      @team_1 = create :approving_team, name: "DACU APPROVING 1"
      @team_2 = create :approving_team, name: "DACU APPROVING 2"
      @flagged_t1 = create :case, :flagged, approving_team: @team_1, name: "Flagged team 1"
      @flagged_t2 = create :case, :flagged, approving_team: @team_2, name: "Flagged team 2"
      @accepted_t1 = create :case, :flagged_accepted, approving_team: @team_1, name: "Accepted team 1"
      @accepted_t2 = create :case, :flagged_accepted, approving_team: @team_2, name: "Accepted team 2"
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe ".flagged_for_approval" do
      context "when passed one team as a parameter" do
        it "returns all the cases flagged for approval by the specified team" do
          expect(described_class.flagged_for_approval(@team_1))
            .to match_array [@flagged_t1, @accepted_t1]
        end
      end

      context "when passed an array of teams as a parameter" do
        it "returns all the cases flagged for approval for all specified teams" do
          expect(described_class.flagged_for_approval(@team_1, @team_2))
            .to match_array [
              @flagged_t1,
              @accepted_t1,
              @flagged_t2,
              @accepted_t2,
            ]
        end
      end
    end

    describe ".flagged_for_approval.unaccepted" do
      context "when one team passsed as a parameter" do
        it "returns only cases flagged which HAVE NOT been accepted" do
          expect(described_class.flagged_for_approval(@team_1).unaccepted)
            .to match_array [@flagged_t1]
        end
      end

      context "when multiple teams passed as a parameter" do
        it "returns only cases flagged which HAVE NOT been accepted" do
          expect(described_class.flagged_for_approval(@team_2, @team_1).unaccepted)
            .to match_array [@flagged_t1, @flagged_t2]
        end
      end
    end

    describe ".flagged_for_approval.accepted" do
      context "when one team passsed as a parameter" do
        it "returns only cases flagged which HAVE been accepted" do
          expect(described_class.flagged_for_approval(@team_1).accepted)
            .to match_array [@accepted_t1]
        end
      end

      context "when multiple teams passsed as a parameter" do
        it "returns only cases flagged which HAVE been accepted" do
          expect(described_class.flagged_for_approval(@team_1, @team_2).accepted)
            .to match_array [@accepted_t1, @accepted_t2]
        end
      end
    end
  end

  describe "default_scope" do
    it "applies a default scope to exclude deleted cases" do
      expect(described_class.all.to_sql).to eq described_class.unscoped.where(deleted: false).to_sql
    end
  end

  describe "open scope" do
    it "returns only closed cases in most recently closed first" do
      open_case, responded_case = nil

      Timecop.freeze(1.minute.ago) do
        open_case = create :case
      end

      Timecop.freeze(2.minutes.ago) do
        responded_case = create :responded_case
      end

      create :closed_case, last_transitioned_at: 2.days.ago
      create :closed_case, last_transitioned_at: 1.day.ago
      expect(described_class.opened).to match_array [open_case, responded_case]
    end
  end

  describe "presented_as_closed scope" do
    it "returns only closed cases and responded and closed icos" do
      create :case
      create :responded_case
      closed_case_1 = create :closed_case, last_transitioned_at: 2.days.ago
      closed_case_2 = create :closed_case, last_transitioned_at: 1.day.ago
      responded_ico = create :responded_ico_foi_case, last_transitioned_at: 1.day.ago

      expect(described_class.presented_as_closed).to match_array [closed_case_1, closed_case_2, responded_ico, responded_ico.original_case]
    end
  end

  describe "closed scope" do
    it "returns only closed cases" do
      create :case
      create :responded_case
      closed_case_1 = create :closed_case, last_transitioned_at: 2.days.ago
      closed_case_2 = create :closed_case, last_transitioned_at: 1.day.ago
      expect(described_class.closed).to match_array [closed_case_1, closed_case_2]
    end
  end

  describe "with_team scope" do
    it "returns cases that are with a given team" do
      create :assigned_case, responding_team: other_responding_team
      expect(described_class.with_teams(responding_team))
        .to match_array([assigned_case])
    end

    it "can accept more than one team" do
      responding_team_b = create :responding_team
      expected_cases = [
        assigned_case,
        create(:assigned_case, responding_team: responding_team_b),
      ]
      expect(described_class.with_teams([responding_team, responding_team_b]))
        .to match_array expected_cases
    end

    it "does not include rejected assignments" do
      expected_cases = [assigned_case]
      create(:rejected_case, responding_team:)
      expect(described_class.with_teams(responding_team)).to match_array(expected_cases)
    end

    it "includes accepted cases" do
      created_cases = [assigned_case, accepted_case]
      expect(described_class.with_teams(responding_team)).to match_array(created_cases)
    end
  end

  describe "not_with_team scope" do
    it "returns cases that are not with a given team" do
      other_assigned_case = create :assigned_case,
                                   responding_team: other_responding_team
      expect(described_class.not_with_teams(responding_team))
        .to match_array([other_assigned_case])
    end
  end

  describe "with_user scope" do
    it "returns cases that are with a given user" do
      create :accepted_case, responder: co_responder
      expect(described_class.with_user(responder)).to match_array([accepted_case])
    end

    it "can accept more than one user" do
      responder_b = create :responder
      expected_cases = [
        accepted_case,
        create(:accepted_case, responder:),
      ]
      expect(described_class.with_user(responder, responder_b))
        .to match_array expected_cases
    end

    it "does not include rejected assignments" do
      expected_cases = [accepted_case]
      create(:rejected_case, responder:)
      expect(described_class.with_user(responder)).to match_array(expected_cases)
    end
  end

  describe "waiting_to_be_accepted scope" do
    it "only returns cases that have not been accepted for team" do
      accepted_case
      expected_cases = [assigned_case]
      expect(described_class.waiting_to_be_accepted(responding_team))
        .to match_array(expected_cases)
    end
  end

  describe "trigger scope" do
    it "returns cases that are in the trigger workflow" do
      trigger_case = create :accepted_case, :flagged
      _standard_case = create :accepted_case
      expect(described_class.trigger).to eq [trigger_case]
    end

    it "returns cases that are in full_approval workflow" do
      press_office_case = create :accepted_case, :flagged, :press_office
      _standard_case = create :accepted_case
      expect(described_class.trigger).to eq [press_office_case]
    end
  end

  describe "non_trigger scope" do
    it "returns cases that are not in the trigger workflow" do
      _trigger_case = create :accepted_case, :flagged
      standard_case = create :accepted_case
      expect(described_class.non_trigger).to eq [standard_case]
    end

    it "returns cases that are in full_approval workflow" do
      _press_office_case = create :accepted_case, :flagged, :press_office
      standard_case = create :accepted_case
      expect(described_class.non_trigger).to eq [standard_case]
    end
  end

  describe "non_offender_sar scope" do
    it "only returns SAR cases" do
      accepted_case
      accepted_sar
      expect(described_class.non_offender_sar).to eq [accepted_sar]
    end
  end

  describe "most_recent_first scope" do
    let!(:case_oldest) { freeze_time { create :case, received_date: 11.business_days.ago } }
    let!(:case_recent) { freeze_time { create :case, received_date: 10.business_days.ago } }

    it "orders cases by their external deadline" do
      expect(described_class.most_recent_first).to eq [case_recent, case_oldest]
    end

    it "re-orders any previous ordering" do
      expect(described_class.by_deadline.most_recent_first).to eq [case_recent, case_oldest]
    end
  end

  context "with open, responded and closed cases in time and late" do
    before do
      Timecop.freeze Date.new(2017, 2, 2) do
        @open_in_time_case = create :accepted_case, received_date: Date.new(2017, 1, 5)
        @open_late_case = create :accepted_case, received_date: Date.new(2017, 1, 4)
        @responded_in_time_case = create :responded_case,
                                         received_date: Date.new(2017, 1, 5)
        @responded_late_case = create :responded_case,
                                      received_date: Date.new(2017, 1, 4)
        @closed_in_time_case = create :closed_case,
                                      received_date: Date.new(2017, 1, 3),
                                      date_responded: Date.new(2017, 1, 31)
        @closed_late_case = create :closed_case,
                                   received_date: Date.new(2017, 1, 3),
                                   date_responded: Date.new(2017, 2, 1)
      end
    end

    describe "in_time scope" do
      it "only returns cases that are not past their deadline" do
        Timecop.freeze Date.new(2017, 2, 2) do
          expect(described_class.in_time).to match_array([
            @open_in_time_case,
            @responded_in_time_case,
            @closed_in_time_case,
          ])
        end
      end
    end

    describe "late scope" do
      it "only returns cases that are past their deadline" do
        Timecop.freeze Date.new(2017, 2, 2) do
          expect(described_class.late).to match_array([
            @open_late_case,
            @responded_late_case,
            @closed_late_case,
          ])
        end
      end
    end
  end

  describe "internal_review_compliance scope" do
    it "returns internal review for compliance FOI cases" do
      _standard_case = create :accepted_case
      ir_compliance_case = create :compliance_review
      expect(described_class.internal_review_compliance).to eq [ir_compliance_case]
    end
  end

  describe "internal_review_timeliness scope" do
    it "returns internal review for timeliness FOI cases" do
      _standard_case = create :accepted_case
      ir_timeliness_case = create :timeliness_review
      expect(described_class.internal_review_timeliness).to eq [ir_timeliness_case]
    end
  end

  describe "presented_as_open scope" do
    let!(:responded_foi)     { create(:responded_case, email: "A@A.com") }
    let!(:approved_sar)      { create(:approved_sar, email: "B@B.com") }
    let!(:accepted_ico_foi) { create(:accepted_ico_foi_case, email: "F@F.com") }
    let!(:accepted_ico_sar) { create(:accepted_ico_sar_case, email: "G@G.com") }

    before do
      create(:closed_case, email: "E@E.com")
      create(:responded_ico_foi_case, email: "C@C.com")
      create(:responded_ico_sar_case, email: "D@D.com")
    end

    it "excludes all closed AND ico case which are responded" do
      expect(described_class.presented_as_open).to match_array([responded_foi, approved_sar, accepted_ico_foi, accepted_ico_sar])
    end
  end

  context "with related teams" do
    let(:responding_team)    { create :responding_team }
    let(:responder)          { responding_team.responders.first }

    let!(:assigned_case) do
      create :assigned_case,
             responding_team:
    end
    let!(:accepted_case) do
      create :accepted_case,
             responder:
    end

    let!(:team1) { accepted_case.responding_team }
    let!(:team2) { assigned_case.responding_team }
    let!(:team3) { accepted_case.managing_team }
    let!(:team4) { assigned_case.managing_team }

    let(:responding_teams) { cases.map(&:responding_team) }
    let(:managing_teams) { cases.map(&:managing_team) }

    context "when non preloaded" do
      let(:cases) { described_class.all }

      it "returns responding teams" do
        expect(responding_teams).to match_array [team1, team2]
      end

      it "returns managing teams" do
        expect(managing_teams).to match_array [team3, team4]
      end
    end

    context "when preloaded" do
      let(:cases) do
        described_class.includes(:responder_assignment,
                                 :responding_team,
                                 :managing_assignment,
                                 :managing_team).all
      end

      it "returns teams for all cases" do
        expect(responding_teams).to match_array [team1, team2]
      end

      it "returns managing teams" do
        expect(managing_teams).to match_array [team3, team4]
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
