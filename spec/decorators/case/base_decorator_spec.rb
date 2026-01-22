require "rails_helper"

describe Case::BaseDecorator, type: :model do
  let(:unassigned_case)     { create(:case).decorate }
  let(:assigned_case)       { create(:assigned_case).decorate }
  let(:accepted_case)       do
    create(:accepted_case,
           responder:,
           responding_team:).decorate
  end
  let(:approved_ico)        { create(:approved_ico_foi_case).decorate }
  let(:responded_ico)       { create(:responded_ico_foi_case).decorate }
  let(:upheld_ico_case)     { create(:closed_ico_foi_case).decorate }
  let(:overturned_ico_case) { create(:closed_ico_foi_case, :overturned_by_ico).decorate }
  let(:responded_case)      { create(:responded_case).decorate }
  let(:closed_case)         { create(:closed_case).decorate }
  let(:manager)             { create :manager, managing_teams: [managing_team] }
  let(:managing_team)       { find_or_create :team_dacu }
  let(:responder)           { create :responder }
  let(:responding_team)     { responder.teams.first }
  let(:coworker)            do
    create :responder,
           responding_teams: responder.responding_teams
  end
  let(:pending_dacu_clearance_case) { create(:pending_dacu_clearance_case).decorate }
  let(:another_responder) { create :responder }
  let(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }

  context "when ensuring the correct decorator is instantiated" do
    context "and Case::FOI::Standard" do
      it "instantiates the correct decorator" do
        expect(Case::FOI::Standard.new.decorate).to be_instance_of Case::FOI::StandardDecorator
      end
    end

    context "and Case::FOI::ComplianceReview" do
      it "instantiates the correct decorator" do
        expect(Case::FOI::ComplianceReview.new.decorate).to be_instance_of Case::FOI::ComplianceReviewDecorator
      end
    end

    context "and Case::FOI::TimelinessReview" do
      it "instantiates the correct decorator" do
        expect(Case::FOI::TimelinessReview.new.decorate).to be_instance_of Case::FOI::TimelinessReviewDecorator
      end
    end
  end

  describe "#who_its_with" do
    context "when case has no responding team assigned" do
      it "returns the managing teams name" do
        expect(unassigned_case.who_its_with)
          .to eq unassigned_case.managing_team.name
      end
    end

    context "when case has been assigned but not accepted yet" do
      it "returns the responding teams name" do
        expect(assigned_case.who_its_with)
          .to eq assigned_case.responding_team.name
      end
    end

    context "when case is accepted by responder" do
      context "and a case manager" do
        it "returns the responding teams name" do
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context "with the responder" do
        it "returns the responder name" do
          allow_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
            .to receive(:h).and_return(double("View", current_user: responder)) # rubocop:disable RSpec/VerifiedDoubles
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context "when a coworker of the responder" do
        it "returns the responder name" do
          allow_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
            .to receive(:h).and_return(double("View", current_user: coworker)) # rubocop:disable RSpec/VerifiedDoubles
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context "when the responder in another team" do
        it "returns the responder name" do
          allow_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
            .to receive(:h)
            .and_return(double("View", current_user: another_responder)) # rubocop:disable RSpec/VerifiedDoubles
          expect(assigned_case.who_its_with)
            .to eq assigned_case.responding_team.name
        end
      end

      context "when flagged case in pending_dacu_clearance state" do
        it "returns dacu disclosure" do
          allow_any_instance_of(described_class) # rubocop:disable RSpec/AnyInstance
            .to receive(:h)
            .and_return(double("View", current_user: another_responder)) # rubocop:disable RSpec/VerifiedDoubles
          expect(pending_dacu_clearance_case.who_its_with).to eq "Disclosure"
        end
      end
    end

    context "when case is responded" do
      it "returns the managing team name" do
        expect(responded_case.who_its_with).to eq managing_team.name
      end
    end
  end

  describe "#time_taken" do
    let(:mon_nov_27) { Time.utc(2023, 11, 27, 12, 0, 0) }

    it "returns the number of business days taken to respond to a case" do
      Timecop.freeze mon_nov_27 do
        expect(closed_case.time_taken).to eq "19 working days"
      end
    end

    it 'uses singular "day" for 1 day' do
      Timecop.freeze mon_nov_27 do
        closed_case_21_days_old =
          create(:closed_case, date_responded: 22.business_days.ago).decorate
        expect(closed_case_21_days_old.time_taken).to eq "1 working day"
      end
    end
  end

  describe "#timeliness" do
    it "returns correct string for answered in time" do
      expect(closed_case.timeliness).to eq "Answered in time"
    end

    it "returns correct string for answered late" do
      closed_late_case = create(:closed_case, :late).decorate
      expect(closed_late_case.timeliness).to eq "Answered late"
    end
  end

  describe "#draft_timeliness" do
    it "returns correct string for answered in time" do
      approved_case = create(:approved_case).decorate
      expect(approved_case.draft_timeliness).to eq "Uploaded in time"
    end

    it "returns correct string for answered late" do
      closed_late_case = create(:closed_case, :late).decorate
      expect(closed_late_case.draft_timeliness).to eq "Uploaded late"
    end
  end

  describe "#internal_deadline" do
    context "when unflagged case" do
      it "returns space" do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.internal_deadline).to eq " "
      end
    end

    context "when flagged case" do
      it "returns the internal deadline" do
        Timecop.freeze(Time.zone.local(2017, 5, 2, 9, 45, 33)) do
          flagged_case = create(:case, :flagged, creation_time: Time.zone.today).decorate
          expect(flagged_case.internal_deadline).to eq "16 May 2017"
        end
      end
    end
  end

  describe "#trigger_case_marker" do
    context "when unflagged case" do
      it "returns space" do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.trigger_case_marker).to eq " "
      end
    end

    context "when flagged case" do
      it "returns the Trigger case badge" do
        flagged_case = create(:case, :flagged).decorate
        expect(flagged_case.trigger_case_marker)
          .to eq '<div class="foi-trigger"><span class="visually-hidden">This is a </span>Trigger<span class="visually-hidden"> case</span></div>'
      end
    end
  end

  describe "#highlight_flag" do
    context "when unflagged case" do
      it "returns space" do
        unflagged_case = create(:case).decorate
        expect(unflagged_case.highlight_flag).to eq " "
      end
    end

    context "when flagged case" do
      it "returns the Trigger case badge" do
        flagged_case = create(:case, :flagged).decorate
        expect(flagged_case.highlight_flag)
          .to eq '<div class="foi-trigger"><span class="visually-hidden">This is a </span>Trigger<span class="visually-hidden"> case</span></div>'
      end
    end
  end

  describe "#external_deadline" do
    it "returns the external deadline" do
      Timecop.freeze(Time.zone.local(2017, 5, 2, 9, 45, 33)) do
        flagged_case = create(:case, :flagged, creation_time: Time.zone.today).decorate
        expect(flagged_case.external_deadline).to eq "31 May 2017"
      end
    end
  end

  describe "#date_sent_to_requester" do
    it "returns formatted version of date responded " do
      Timecop.freeze(Time.zone.local(2017, 5, 2, 9, 45, 33)) do
        closed_case = create(:closed_case).decorate
        expect(closed_case.date_sent_to_requester).to eq "25 Apr 2017"
      end
    end
  end

  describe "#requester_name_and_type" do
    it "returns name and requestor type" do
      kase = create(:case, name: "Stepriponikas Bonstart", requester_type: "member_of_the_public").decorate
      expect(kase.requester_name_and_type).to eq "Stepriponikas Bonstart | member_of_the_public"
    end

    it "returns the name and subject type" do
      kase = create(:sar_case, name: "Wade Wilson", subject_type: "staff").decorate
      expect(kase.requester_name_and_type).to eq "Wade Wilson | staff"
    end
  end

  describe "#message_extract" do
    context "when message fewer than 360 chars" do
      it "returns the entire message" do
        kase = create(:case, message: "One fine day.").decorate
        expect(kase.message_extract.size).to eq 1
        expect(kase.message_extract.first).to eq kase.message
      end
    end

    context "when message more than 360 characters" do
      it "returns an array with two entries" do
        long_message =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " \
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " \
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."

        first_part =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
          "and going through th"

        second_part =
          "e cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " \
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " \
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."
        kase = create(:case, message: long_message).decorate

        expect(kase.message_extract.size).to eq 2
        expect(kase.message_extract.first).to eq first_part
        expect(kase.message_extract.second).to eq second_part
      end
    end
  end

  describe "#shortened_message" do
    context "when message fewer than 360 chars" do
      it "returns the entire message" do
        kase = create(:case, message: "One fine day.").decorate
        expect(kase.shortened_message).to eq kase.message
      end
    end

    context "when message more than 360 characters" do
      it "returns shortened message with ellipsis" do
        long_message =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, " \
          "and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum " \
          "comes from sections 1.10.32 and 1.10.33 of 'de Finibus Bonorum et Malorum' (The Extremes of Good and Evil) by " \
          "Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. " \
          "The first line of Lorem Ipsum, 'Lorem ipsum dolor sit amet', comes from a line in section 1.10.32."

        short_message =
          "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin " \
          "literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney " \
          "College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage,  " \
          "and going through th..."

        kase = create(:case, message: long_message).decorate

        expect(kase.shortened_message).to eq short_message
      end
    end
  end

  describe "#status" do
    it "returns a closed status" do
      expect(closed_case.status).to eq "Closed"
    end

    it "returns a unassigned status" do
      expect(unassigned_case.status).to eq "Needs reassigning"
    end

    it "returns a assigned status" do
      expect(assigned_case.status).to eq "To be accepted"
    end

    it "returns a accepted status" do
      expect(accepted_case.status).to eq "Draft in progress"
    end

    it "returns a responded status" do
      expect(responded_case.status).to eq "Ready to close"
    end

    it "returns a awaiting_dispatch status for ico" do
      expect(approved_ico.status).to eq "Ready to send to ICO"
    end

    it "returns a responded status for ico" do
      expect(responded_ico.status).to eq "Closed - awaiting ICO decision"
    end

    context "when closed ico - ICO decisions" do
      it "returns a closed status with upheld" do
        expect(upheld_ico_case.status).to eq "Closed - upheld by ICO"
      end

      it "returns a closed status with overturned" do
        expect(overturned_ico_case.status).to eq "Closed - overturned by ICO"
      end
    end
  end

  describe "#escaltion_deadline" do
    it "returns the escalation date in the default format" do
      allow(unassigned_case.object).to receive(:escalation_deadline).and_return(Date.new(2017, 8, 13))
      expect(unassigned_case.escalation_deadline).to eq "13 Aug 2017"
    end
  end

  describe "#date_draft_compliant" do
    it "returns the the draft upload date in the default format" do
      allow(closed_case.object).to receive(:date_draft_compliant).and_return(Date.new(2017, 8, 14))
      expect(closed_case.date_draft_compliant).to eq "14 Aug 2017"
    end
  end

  describe "#has_date_draft_compliant?" do
    it "returns true when there is an underlying date_draft_compliant" do
      allow(closed_case.object).to receive(:date_draft_compliant).and_return(Date.new(2017, 8, 14))
      expect(closed_case.has_date_draft_compliant?).to eq true
    end

    it "returns false when there is not an underlying date_draft_compliant" do
      allow(closed_case.object).to receive(:date_draft_compliant).and_return(nil)
      expect(closed_case.has_date_draft_compliant?).to eq false
    end
  end

  describe "#message_notification_visible?" do
    context "when transitions tracker for case and user exists" do
      let(:tracker) do
        instance_double CasesUsersTransitionsTracker,
                        present?: true
      end

      before do
        allow(accepted_case).to receive(:transition_tracker_for_user)
                                  .and_return(tracker)
      end

      it "returns true if the tracker is not up-to-date" do
        allow(tracker).to receive(:is_up_to_date?).and_return(false)
        expect(accepted_case.message_notification_visible?(responder))
          .to eq true
      end

      it "returns false if the tracker is up-to-date" do
        allow(tracker).to receive(:is_up_to_date?).and_return(true)
        expect(accepted_case.message_notification_visible?(responder))
          .to eq false
      end
    end

    context "when transitions tracker does not exist" do
      let(:tracker) do
        instance_double CasesUsersTransitionsTracker,
                        present?: false
      end

      before do
        allow(accepted_case).to receive(:transition_tracker_for_user)
                                  .and_return(tracker)
      end

      it "returns true if the case has any messages" do
        accepted_case.state_machine
          .add_message_to_case!(acting_user: responder, acting_team: responding_team, message: "up-to-date")
        expect(accepted_case.message_notification_visible?(responder))
          .to eq true
      end

      it "returns false if the case has any messages" do
        expect(accepted_case.message_notification_visible?(responder))
          .to eq false
      end
    end
  end

  describe "#type_printer" do
    it "pretty prints Case" do
      expect(accepted_case.pretty_type).to eq "FOI"
    end
  end

  describe "#closed_case_name" do
    let(:offender_sar_case) { build_stubbed(:offender_sar_case, subject: "The case subject") }

    context "when name" do
      context "and is not empty" do
        it "returns existing case name" do
          offender_sar_case.name = "Monalisa Khan"
          expect(offender_sar_case.decorate.closed_case_name).to eq "Monalisa Khan"
        end
      end
    end

    context "when is empty" do
      it "returns case subject instead" do
        offender_sar_case.name = ""
        expect(offender_sar_case.decorate.closed_case_name).to eq "The case subject"
      end
    end
  end
end
