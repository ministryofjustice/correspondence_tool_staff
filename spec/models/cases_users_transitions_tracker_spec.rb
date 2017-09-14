require "rails_helper"

describe CasesUsersTransitionsTracker do
  let(:kase)    { create :accepted_case }
  let(:user)    { kase.responder }
  let(:tracker) { CasesUsersTransitionsTracker.find_or_create_by case: kase,
                                                                 user: user  }

  describe '.sync_for_case_and_user' do
    context 'tracker exists for given case and user' do
      before do
        tracker
      end

      it 'does not create a new tracker' do
        expect(kase.users_transitions_trackers.where(user: user).count).to eq 1
      end

      it 'updates the existing tracker' do
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        tracker.reload
        expect(tracker.case_transition_id).to eq kase.transitions.last.id
      end
    end

    context 'tracker does not exists for given case and user' do
      it 'creates a new tracker' do
        expect(kase.users_transitions_trackers.where(user: user).count).to eq 0
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        expect(kase.users_transitions_trackers.where(user: user).count).to eq 1
      end

      it 'sets the transition id on the new tracker' do
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        expect(tracker.case_transition_id).to eq kase.transitions.last.id
      end
    end
  end
end
