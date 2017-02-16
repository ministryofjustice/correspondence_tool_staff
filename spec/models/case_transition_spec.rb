# == Schema Information
#
# Table name: case_transitions
#
#  id          :integer          not null, primary key
#  event       :string
#  to_state    :string           not null
#  metadata    :jsonb
#  sort_key    :integer          not null
#  case_id     :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

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
