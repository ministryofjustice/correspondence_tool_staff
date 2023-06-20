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

RSpec.describe Team, type: :model do
  let(:team) { build_stubbed :team }

  it "can be created" do
    bu = described_class.create! name: "Busy Units", email: "busy.units@localhost"
    expect(bu).to be_valid
  end

  it {
    expect(subject).to have_many(:user_roles)
                .class_name("TeamsUsersRole")
  }

  it { is_expected.to have_many(:users).through(:user_roles) }

  describe "code" do
    it "has a code of null by default" do
      expect(team.code).to be_nil
    end
  end

  describe "email" do
    it "considers team emails to be case-insensitive" do
      team = described_class.create! name: "test", email: "TEST@localhost"
      expect(described_class.find_by(email: "test@localhost")).to eq team
    end
  end

  context "when validate uniqueness of name" do
    it "errors if not unique" do
      create :team, name: "abc"
      t2 = build_stubbed :team, name: "abc"
      expect(t2).not_to be_valid
      expect(t2.errors[:name]).to eq ["has already been taken"]
    end
  end

  context "when multiple teams created" do
    let!(:managing_team)       { find_or_create :team_disclosure_bmt }
    let!(:branston_team)       { find_or_create :team_branston }
    let!(:responding_team)     { find_or_create :foi_responding_team }
    let!(:sar_responding_team) { find_or_create :sar_responding_team }
    let!(:approving_team)      { find_or_create :team_disclosure }

    describe "managing scope" do
      it "returns managing teams" do
        expect(BusinessUnit.managing).to match_array [managing_team]
      end
    end

    describe "responding scope" do
      it "returns only responding teams" do
        expect(BusinessUnit.responding).to match_array [
          responding_team,
          sar_responding_team,
          branston_team,
        ]
      end
    end

    describe "approving scope" do
      it "returns only approving teams" do
        expect(BusinessUnit.approving).to match_array [
          BusinessUnit.press_office,
          BusinessUnit.private_office,
          BusinessUnit.dacu_disclosure,
        ]
      end
    end
  end

  it "has a working factory" do
    expect(create(:team)).to be_valid
  end

  context "when specific team finding and querying" do
    before(:all) do
      @press_office_team = find_or_create :team_press_office
      @private_office_team = find_or_create :team_private_office
      @dacu_disclosure_team = find_or_create :team_dacu_disclosure
    end

    after(:all) do
      DbHousekeeping.clean
    end

    describe ".dacu_disclosure" do
      it "finds the DACU Disclosure team" do
        expect(BusinessUnit.dacu_disclosure).to eq @dacu_disclosure_team
      end
    end

    describe "#dacu_disclosure?" do
      it "returns true if dacu disclosure" do
        expect(@dacu_disclosure_team.dacu_disclosure?).to be true
      end

      it "returns false if not dacu disclosure" do
        expect(@press_office_team.dacu_disclosure?).to be false
      end
    end

    describe ".press_office" do
      it "finds the Press Office team" do
        expect(BusinessUnit.press_office).to eq @press_office_team
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
        expect(BusinessUnit.private_office).to eq @private_office_team
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

  describe "scope with_user" do
    it "lists teams with a given user" do
      t1 = create :business_unit
      t2 = create :business_unit
      u1 = create :user
      u2 = create :user
      u1.managing_teams << t1
      u2.managing_teams << t2
      expect(described_class.with_user(u1)).to eq [t1]
    end
  end

  describe "#can_allocate?" do
    before do
      @team = build_stubbed :team
      @foi = create :foi_correspondence_type
      @gq = create :gq_correspondence_type
      create :team_property, :can_allocate_gq, team_id: @team.id
    end

    it "returns false if there is no team property with key can_allocate for specified correspondence type" do
      expect(@team.can_allocate?(@foi)).to be false
    end

    it "returns true if there is a team property key can_allocate for specified correspondence type" do
      expect(@team.can_allocate?(@gq)).to be true
    end
  end

  describe "#enable_allocation" do
    let(:foi) { create :foi_correspondence_type }

    it "creates a team property record" do
      expect(TeamProperty.where(key: "can_allocate", value: foi.abbreviation).size).to eq 0
      team.enable_allocation(foi)
      expect(TeamProperty.where(key: "can_allocate", value: foi.abbreviation).size).to eq 1
    end

    it "does not duplicate the team property record if one already exists" do
      expect(TeamProperty.where(key: "can_allocate", value: foi.abbreviation).size).to eq 0
      team.enable_allocation(foi)
      team.enable_allocation(foi)
      expect(TeamProperty.where(key: "can_allocate", value: foi.abbreviation).size).to eq 1
    end
  end

  describe "#disable_allocation" do
    before do
      @team = build_stubbed :team
      @foi = create :foi_correspondence_type
      create :team_property, :can_allocate_foi, team_id: @team.id
    end

    it "deletes the team property" do
      expect(@team.properties).to exist(key: "can_allocate", value: "FOI")
      @team.disable_allocation(@foi)
      expect(@team.properties).not_to exist(key: "can_allocate", value: "FOI")
    end

    it "doesnt fail if called twice" do
      expect(@team.properties).to exist(key: "can_allocate", value: "FOI")
      @team.disable_allocation(@foi)
      @team.disable_allocation(@foi)
      expect(@team.properties).not_to exist(key: "can_allocate", value: "FOI")
    end
  end

  describe ".allocatable" do
    it "returns a collection of teams that have the can_allocate property set for the correspondence type" do
      foi = create :foi_correspondence_type
      gq = create :gq_correspondence_type
      t1 = create :team
      t2 = create :team
      t3 = create :team
      t4 = create :team
      [t1, t2, t4].each { |t| t.enable_allocation(foi) }
      [t3, t4].each { |t| t.enable_allocation(gq) }
      expect(described_class.allocatable(foi)).to match_array [t1, t2, t4]
      expect(described_class.allocatable(gq)).to match_array [t3, t4]
    end
  end

  describe ".team_lead" do
    it "returns the value for the team lead property" do
      team = create :team, team_lead: "A Team Lead"
      expect(team.team_lead).to eq "A Team Lead"
    end
  end

  describe ".team_lead=" do
    it "creates the value for the team lead property" do
      team.team_lead = "A New Team Lead"
      expect(team.properties.lead.first.value).to eq "A New Team Lead"
    end

    it "sets the value for the team lead property" do
      team.properties << TeamProperty.new(key: "lead", value: "A Team Lead")
      team.team_lead = "A Newer Team Lead"
      expect(team.properties.lead.first.value).to eq "A Newer Team Lead"
    end
  end

  describe "paper_trail versions", versioning: true do
    it "has versions" do
      expect(subject).to be_versioned
    end

    context "when creating" do
      it "updates versions" do
        team = create :team
        expect(team.versions.length).to eq 1
        expect(team.versions.last.event).to eq "create"
      end
    end

    context "when updating" do
      it "updates versions" do
        team = create :team
        expect { team.update!(name: "Name Changing Unit") }.to change(team.versions, :count).by 1
        expect(team.versions.last.event).to eq "update"
      end
    end
  end

  describe "#has_active_children?" do
    let(:dir) { create :directorate }

    context "when a directorate has active children" do
      let!(:bu) { create(:business_unit, directorate: dir) }

      it "returns true" do
        expect(dir.has_active_children?).to be true
      end
    end

    context "when a directorate has no children" do
      it "returns false" do
        expect(dir.has_active_children?).to be false
      end
    end

    context "when a directorate has deactived children" do
      let!(:bu) { create(:business_unit, :deactivated, directorate: dir) }

      it "returns false" do
        expect(dir.has_active_children?).to be false
      end
    end
  end

  describe "#original_team_name" do
    let!(:bu) do
      create(
        :business_unit,
        :deactivated, name: "[DEACTIVATED] The Avengers @(2022-01-21 13:21)"
      )
    end

    it "excludes DEACTIVATED and DateTime from the name" do
      expect(bu.original_team_name).to eq "The Avengers"
    end
  end
end
