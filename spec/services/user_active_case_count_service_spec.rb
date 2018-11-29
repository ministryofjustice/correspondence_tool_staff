require 'rails_helper'

describe UserActiveCaseCountService do

  let(:responding_team)   { find_or_create :foi_responding_team }
  let(:user_1)            { find_or_create :foi_responder }
  let(:user_2)            { create :foi_responder, identifier: 'foi responder 2' }
  let(:users)             { [ user_1, user_2] }
  let!(:kase_1)           { create :accepted_case, responder: user_1 }
  let!(:kase_2)           { create :accepted_case, responder: user_1 }
  let!(:kase_3)           { create :accepted_case, responder: user_2 }
  let!(:kase_4)           { create :closed_case, responder: user_2 }
  let(:service)           { UserActiveCaseCountService.new }

  describe '#case_counts_by_user' do
    it 'returns number of cases indexed by user id' do
      case_counts = service.case_counts_by_user(users)
      expect(case_counts).to eq(
           {
               user_1.id => 2,
               user_2.id => 1
           })
    end
  end

  describe '#active_cases_for_user' do
    it 'returns active cases for user' do
      expected = [ kase_1, kase_2 ]
      expect(service.active_cases_for_user(user_1)).to eq expected
    end

    it "works with admins" do
      admin = create :admin, responding_teams: [responding_team]
      expect(service.active_cases_for_user(admin)).to be_empty
    end
  end
end
