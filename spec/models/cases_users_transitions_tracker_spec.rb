# == Schema Information
#
# Table name: cases_users_transitions_trackers
#
#  id                 :integer          not null, primary key
#  case_id            :integer
#  user_id            :integer
#  case_transition_id :integer
#  created_at         :datetime
#  updated_at         :datetime
#

require "rails_helper"

describe CasesUsersTransitionsTracker do
  let(:kase)    { create :accepted_case }
  let(:user)    { kase.responder }
  let(:tracker) do
    described_class.create case: kase,
                           user:
  end

  describe "uniqueness validation" do
    it "prevents two records for that same case id and user id being created " do
      expect {
        described_class.create!(case: tracker.case, user: tracker.user)
      }.to raise_error ActiveRecord::RecordInvalid, "Validation failed: User has already been taken"
    end
  end

  describe ".sync_for_case_and_user" do
    context "when tracker exists for given case and user" do
      before do
        tracker
      end

      it "does not create a new tracker" do
        expect(kase.users_transitions_trackers.where(user:).count).to eq 1
      end

      context "and case has messages" do
        let!(:message) { create :case_transition_add_message_to_case, case: kase }

        it "updates the existing tracker" do
          described_class.sync_for_case_and_user(kase, user)
          tracker.reload
          expect(tracker.case_transition_id).to eq message.id
        end
      end

      context "and case has no messages" do
        it "does not update the tracker" do
          described_class.sync_for_case_and_user(kase, user)
          tracker.reload
          expect(tracker.case_transition_id).to eq nil
        end
      end
    end
  end

  context "when tracker does not exists for given case and user" do
    context "and case has messages" do
      before do
        create :case_transition_add_message_to_case, case: kase
      end

      it "creates a new tracker" do
        expect(kase.users_transitions_trackers.where(user:).count)
          .to eq 0
        described_class.sync_for_case_and_user(kase, user)
        expect(kase.users_transitions_trackers.where(user:).count)
          .to eq 1
      end

      it "sets the transition id on the new tracker" do
        described_class.sync_for_case_and_user(kase, user)
        new_tracker = described_class.find_by(case: kase,
                                              user:)
        expect(new_tracker.case_transition_id).to eq kase.transitions.last.id
      end
    end

    context "and case has no messages" do
      it "does not create a new tracker" do
        described_class.sync_for_case_and_user(kase, user)
        expect(kase.users_transitions_trackers.where(user:).count)
          .to eq 0
      end
    end
  end
end
