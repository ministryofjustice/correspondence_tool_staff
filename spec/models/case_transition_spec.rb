require 'rails_helper'

RSpec.describe CaseTransition, type: :model do

  describe 'after_destroy' do

    let(:kase)          { create(:case) }
    
    let(:case_assigned) do
      create(
        :case_transition_assign_responder,
        case_id: kase.id
      )
    end
    
    let(:assignment_accepted) do
      create(
        :case_transition_accept_responder_assignment,
        case_id: kase.id
      )
    end

    before do
      kase
      case_assigned
      assignment_accepted
    end

    it 'updates most_recent' do
      expect(case_assigned.reload.most_recent).to eq false
      expect(assignment_accepted.reload.most_recent).to eq true
      assignment_accepted.destroy
      expect(case_assigned.reload.most_recent).to eq true
    end
  end
end
