require 'rails_helper'

describe CaseDecorator, type: :model do
  let(:unassigned_case) { create(:case).decorate }
  let(:assigned_case)   { create(:assigned_case).decorate }
  let(:accepted_case)   { create(:accepted_case,
                                 responder: responder).decorate }
  let(:responded_case)  { create(:responded_case).decorate }
  let(:closed_case)     { create(:closed_case).decorate }
  let(:manager)         { create :manager, managing_teams: [managing_team] }
  let(:managing_team)   { find_or_create :team_dacu }
  let(:responder)       { create :responder }
  let(:responding_team) { responder.teams.first }
  let(:coworker)        { create :responder,
                                 responding_teams: responder.responding_teams }
  let(:pending_dacu_clearance_case) { create(:pending_dacu_clearance_case).decorate }
  let(:another_responder) { create :responder }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }


  describe '#who_its_with' do
    context 'case has no responding team assigned' do
      it 'returns the managing teams name' do
        expect(unassigned_case.who_its_with)
          .to eq unassigned_case.managing_team.name
      end
    end

    context 'case has been assigned but not accepted yet' do
      it 'returns the responding teams name' do
        expect(assigned_case.who_its_with)
          .to eq assigned_case.responding_team.name
      end
    end

    context 'case is accepted by responder' do
      context 'as a case manager' do
        it 'returns the responding teams name' do
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h).and_return(double("View", current_user: responder))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as a coworker of the responder' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h).and_return(double("View", current_user: coworker))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'as the responder in another team' do
        it 'returns the responder name' do
          allow_any_instance_of(CaseDecorator)
            .to receive(:h)
                  .and_return(double("View", current_user: another_responder))
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context 'flagged case in pending_dacu_clearance state' do
        it 'returns dacu disclosure' do
          allow_any_instance_of(CaseDecorator).to receive(:h).and_return(double("View", current_user: another_responder))
          expect(pending_dacu_clearance_case.who_its_with).to eq 'Disclosure'
        end
      end
    end

    context 'case is responded' do
      it 'returns the managing team name' do
        expect(responded_case.who_its_with).to eq managing_team.name
      end
    end
  end

  describe '#time_taken' do
    it 'returns the number of business days taken to respond to a case' do
      expect(closed_case.time_taken).to eq '18 working days'
    end

    it 'uses singular "day" for 1 day' do
      closed_case_21_days_old =
        create(:closed_case, date_responded: 21.business_days.ago).decorate
      expect(closed_case_21_days_old.time_taken).to eq '1 working day'
    end
  end

  describe '#timeliness' do
    it 'returns correct string for answered in time' do
      expect(closed_case.timeliness).to eq 'Answered in time'
    end

    it 'returns correct string for answered late' do
      closed_late_case = create(:closed_case, :late).decorate
      expect(closed_late_case.timeliness).to eq 'Answered late'
    end
  end

  describe '#internal_deadline' do
    context 'unflagged case' do
      it 'returns space' do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.internal_deadline).to eq ' '
      end
    end

    context 'flagged case' do
      it 'returns the internal deadline' do
        Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
          flagged_case = create(:case, :flagged).decorate
          expect(flagged_case.internal_deadline).to eq '16 May 2017'
        end
      end
    end
  end

  describe '#internal_deadline' do
    context 'unflagged case' do
      it 'returns space' do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.internal_deadline).to eq ' '
      end
    end

    context 'flagged case' do
      it 'returns the internal deadline' do
        Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
          flagged_case = create(:case, :flagged).decorate
          expect(flagged_case.internal_deadline).to eq '16 May 2017'
        end
      end
    end
  end

  describe '#external_deadline' do
    it 'returns the external deadline' do
      Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
        flagged_case = create(:case, :flagged).decorate
        expect(flagged_case.external_deadline).to eq '31 May 2017'
      end
    end
  end

  describe '#date_sent_to_requester' do
    it 'returns formatted version of date responded ' do
      Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
        closed_case = create(:closed_case).decorate
        expect(closed_case.date_sent_to_requester).to eq '25 Apr 2017'
      end
    end
  end


  describe '#requester_name_and_type' do
    it 'returns name and requestor type' do
      kase = create(:case, name: 'Stepriponikas Bonstart', requester_type: 'member_of_the_public').decorate
      expect(kase.requester_name_and_type).to eq 'Stepriponikas Bonstart | Member of the public'
    end
  end

  describe '#message_extract' do
    context 'message fewer than 360 chars' do
      it 'returns the entire message' do
        kase = create(:case, message: 'One fine day.').decorate
        expect(kase.message_extract.size).to eq 1
        expect(kase.message_extract.first).to eq kase.message
      end
    end

    context 'message more than 360 characters' do
      it 'returns an array with two entries' do
        long_message =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney "+
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."

        first_part =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
          "and going through th"

        second_part =
          "e cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
        kase = create(:case, message: long_message).decorate

        expect(kase.message_extract.size).to eq 2
        expect(kase.message_extract.first).to eq first_part
        expect(kase.message_extract.second).to eq second_part

      end
    end
  end

  describe '#shortened_message' do
    context 'message fewer than 360 chars' do
      it 'returns the entire message' do
        kase = create(:case, message: 'One fine day.').decorate
        expect(kase.shortened_message).to eq kase.message
      end
    end

    context 'message more than 360 characters' do
      it 'returns shortened message with ellipsis' do
        long_message =
            "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
                "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney "+
                "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
                "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
                "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
                "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
                "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " +
                "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " +
                "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " +
                "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " +
                "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."

        short_message =
            "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " +
                "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " +
                "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " +
                "and going through th..."

        kase = create(:case, message: long_message).decorate

        expect(kase.shortened_message).to eq short_message
      end
    end


  end

  describe '#status' do
    it 'returns a closed status' do
      expect(closed_case.status).to eq 'Case closed'
    end

    it 'returns a unassigned status' do
      expect(unassigned_case.status).to eq 'Needs reassigning'
    end

    it 'returns a assigned status' do
      expect(assigned_case.status).to eq 'To be accepted'
    end

    it 'returns a responded status' do
      expect(accepted_case.status).to eq 'Draft in progress'
    end

    it 'returns a responded status' do
      expect(responded_case.status).to eq 'Ready to close'
    end
  end

  describe '#escaltion_deadline' do
    it 'returns the escalation date in the default format' do
      expect(unassigned_case.object).to receive(:escalation_deadline).and_return(Date.new(2017, 8, 13))
      expect(unassigned_case.escalation_deadline).to eq '13 Aug 2017'
    end
  end

  describe '#message_notification_visible?' do
    context 'transitions tracker for case and user exists' do
      let(:tracker) { instance_double CasesUsersTransitionsTracker,
                                      present?: true }

      before do
        allow(accepted_case).to receive(:transition_tracker_for_user)
                                  .and_return(tracker)
      end

      it 'returns true if the tracker is not up-to-date' do
        allow(tracker).to receive(:is_up_to_date?).and_return(false)
        expect(accepted_case.message_notification_visible?(responder))
          .to eq true
      end

      it 'returns false if the tracker is up-to-date' do
        allow(tracker).to receive(:is_up_to_date?).and_return(true)
        expect(accepted_case.message_notification_visible?(responder))
          .to eq false
      end
    end

    context 'transitions tracker does not exist' do
      let(:tracker) { instance_double CasesUsersTransitionsTracker,
                                      present?: false }

      before do
        allow(accepted_case).to receive(:transition_tracker_for_user)
                                  .and_return(tracker)
      end

      it 'returns true if the case has any messages' do
        accepted_case.state_machine.
          add_message_to_case!(responder, responding_team, 'up-to-date')
        expect(accepted_case.message_notification_visible?(responder))
          .to eq true
      end

      it 'returns false if the case has any messages' do
        accepted_case.state_machine.
          add_message_to_case!(responder, responding_team, 'up-to-date')
        expect(accepted_case.message_notification_visible?(responder))
          .to eq true
      end
    end
  end
end

