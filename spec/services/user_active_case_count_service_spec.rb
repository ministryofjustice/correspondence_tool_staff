require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
describe UserActiveCaseCountService do
  before(:all) do
    DbHousekeeping.clean(seed: true)
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  let(:responding_team)   { create :foi_responding_team }
  let(:user_1)            { create :foi_responder, identifier: "foi responder 1" }
  let(:user_2)            { create :foi_responder, identifier: "foi responder 2" }
  let(:users)             { [user_1, user_2] }
  let(:service)           { described_class.new }
  let!(:kase_1)           { create :accepted_case, responder: user_1 }
  let!(:kase_2)           { create :accepted_case, responder: user_1 }
  let!(:kase_3)           { create :accepted_case, responder: user_2 }
  let!(:kase_4)           { create :closed_case, responder: user_2 }
  let(:service)           { described_class.new }

  describe "#case_counts_by_user" do
    it "returns number of cases indexed by user id" do
      expect(Case::Base.all.count).to eq 4
      expect(kase_1.responder).to eq user_1
      expect(kase_2.responder).to eq user_1
      expect(kase_3.responder).to eq user_2
      expect(kase_4.responder).to eq user_2
      expect(user_1.permitted_correspondence_types.include?(CorrespondenceType.foi)).to eq true
      case_counts = service.case_counts_by_user(users)
      expect(case_counts).to eq(
        {
          user_1.id => 2,
          user_2.id => 1,
        },
      )
    end
  end

  describe "#active_cases_for_user" do
    it "returns active cases for user" do
      expected = [kase_1, kase_2]
      expect(service.active_cases_for_user(user_1)).to match_array expected
    end

    it "works with admins" do
      admin = create :admin, responding_teams: [responding_team]
      expect(service.active_cases_for_user(admin)).to be_empty
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
