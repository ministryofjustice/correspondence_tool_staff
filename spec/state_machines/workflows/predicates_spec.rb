require 'rails_helper'

module Workflows
  describe Predicates do

    describe '#responder_is_member_of_assigned_team?' do
      context 'responder is not a member of assigned team' do
        it 'returns false' do
          kase = create :awaiting_responder_case
          responder = create :responder
          predicate = Predicates.new(user: responder, kase: kase)
          expect(predicate.responder_is_member_of_assigned_team?).to be false
        end
      end

      context 'responder is a member of assigned team' do
        it 'returns true' do
          kase = create :awaiting_responder_case
          responder = kase.responding_team.users.first
          predicate = Predicates.new(user: responder, kase: kase)
          expect(predicate.responder_is_member_of_assigned_team?).to be true
        end
      end
    end
  end
end
