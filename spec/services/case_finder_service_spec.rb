require "rails_helper"

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe CaseFinderService do
  def dd(day)
    Date.new(2016, 11, day)
  end

  let(:empty_collection) { CaseDecorator.decorate_collection([]) }

  describe "cases for responders and flagged dacu disclosure" do
    before(:all) do
      Timecop.freeze Date.new(2016, 11, 25) do
        @manager               = create :manager
        @responder             = find_or_create :foi_responder
        @branston_responder    = find_or_create :branston_user

        @disclosure_specialist = find_or_create :disclosure_specialist

        @responding_team = @responder.responding_teams.first
        @other_responding_team = create :responding_team
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure
        @managing_team        = find_or_create :managing_team

        @closed_case_1 =
          create(:closed_case, :granted_in_full,
                 received_date: dd(17),
                 date_responded: dd(22),
                 identifier: "00-closed case 1")
        @older_case_1 =
          create(:case,
                 received_date: dd(15),
                 identifier: "01-older case 1")
        @newer_case_1 =
          create(:case,
                 received_date: dd(17),
                 identifier: "02-newer case 1")
        @case_1 =
          create(:case,
                 received_date: dd(16),
                 identifier: "03-case 1")
        @case_2 =
          create(:case,
                 received_date: dd(16),
                 identifier: "04-case 2")
        @newer_case_2 =
          create(:case,
                 received_date: dd(17),
                 identifier: "05-newer case 2")
        @older_case_2 =
          create(:case,
                 received_date: dd(15),
                 identifier: "06-older case 2")
        @closed_case_2 =
          create(:closed_case, :granted_in_full,
                 received_date: dd(15),
                 date_responded: dd(23),
                 identifier: "07-closed case 2")
        @assigned_newer_case =
          create(:awaiting_responder_case,
                 received_date: dd(17),
                 identifier: "08-assigned newer case")
        @assigned_older_case =
          create(:awaiting_responder_case,
                 received_date: dd(15),
                 identifier: "09-old assigned case")
        @assigned_other_team =
          create(:awaiting_responder_case,
                 received_date: dd(17),
                 responding_team: @other_responding_team,
                 identifier: "10-assigned other team")
        @newer_dacu_flagged_case =
          create(:case, :flagged,
                 received_date: dd(17),
                 identifier: "11-newer flagged case")
        @older_dacu_flagged_case =
          create(:case, :flagged,
                 received_date: dd(15),
                 identifier: "12-older flagged case")
        @closed_dacu_flagged_case =
          create(:closed_case, :flagged,
                 received_date: dd(15),
                 date_responded: dd(22),
                 identifier: "00-closed flagged case")
        @newer_dacu_flagged_accept =
          create(:case, :flagged_accepted,
                 received_date: dd(17),
                 identifier: "13-newer dacu flagged accept")
        @older_dacu_flagged_accept =
          create(:case, :flagged_accepted,
                 received_date: dd(15),
                 identifier: "14-older dacu flagged accept")
        @accepted_case =
          create(:accepted_case,
                 identifier: "15-accepted case")

        @approved_ico =
          create(:approved_ico_foi_case,
                 original_case: create(:closed_case, :granted_in_full,
                                       received_date: dd(17),
                                       date_responded: dd(22),
                                       identifier: "16A-original closed case for 16-approved_ico"),
                 identifier: "16-approved ico")

        @responded_ico =
          create(:responded_ico_foi_case,
                 original_case: create(:closed_case, :granted_in_full,
                                       received_date: dd(17),
                                       date_responded: dd(22),
                                       identifier: "17A-original closed case for 17-responded-ico"),
                 identifier: "17-responded ico")

        @overturned_ico_sar_original =
          create(:closed_sar,
                 identifier: "18A-original closed sar for 18-overturned ico sar")
        @overturned_ico_sar_original_appeal =
          create(:closed_ico_sar_case, :overturned_by_ico,
                 original_case: @overturned_ico_sar_original,
                 identifier: "18B-original ico appeal for 18-overturned ico sar")
        @overturned_ico_sar =
          create :overturned_ico_sar,
                 original_case: @overturned_ico_sar_original,
                 original_ico_appeal: @overturned_ico_sar_original_appeal,
                 identifier: "18-overturned ico sar"

        @awaiting_responder_overturned_ico_sar_original =
          create(:closed_sar,
                 identifier: "19A-original closed sar for 19-awaiting responder overturned ico sar")
        @awaiting_responder_overturned_ico_sar_original_appeal =
          create(:closed_ico_sar_case, :overturned_by_ico,
                 original_case: @awaiting_responder_overturned_ico_sar_original,
                 identifier: "19B-original ico appeal for 19-overturned ico sar")
        @awaiting_responder_overturned_ico_sar =
          create :awaiting_responder_ot_ico_sar,
                 original_case: @awaiting_responder_overturned_ico_sar_original,
                 original_ico_appeal: @awaiting_responder_overturned_ico_sar_original_appeal,
                 identifier: "19-awaiting responder overturned ico sar"

        @accepted_overturned_ico_sar_original =
          create(:closed_sar,
                 identifier: "20A-original closed sar for 19-awaiting responder overturned ico sar")
        @accepted_overturned_ico_sar_original_appeal =
          create(:closed_ico_sar_case, :overturned_by_ico,
                 original_case: @accepted_overturned_ico_sar_original,
                 identifier: "20B-original ico appeal for 18-overturned ico sar")
        @accepted_overturned_ico_sar =
          create :accepted_ot_ico_sar,
                 original_case: @accepted_overturned_ico_sar_original,
                 original_ico_appeal: @accepted_overturned_ico_sar_original_appeal,
                 identifier: "20-accepted overturned ico sar"
        @closed_overturned_ico_sar =
          create :closed_ot_ico_sar,
                 original_case: @accepted_overturned_ico_sar_original,
                 original_ico_appeal: @accepted_overturned_ico_sar_original_appeal,
                 identifier: "21-closed overturned ico sar"
        @overturned_ico_foi_original =
          create(:closed_case,
                 responder: @responder,
                 identifier: "22A-original closed foi for 18-overturned ico foi")
        @overturned_ico_foi_original_appeal =
          create(:closed_ico_foi_case, :overturned_by_ico,
                 responder: @responder,
                 responding_team: @responding_team,
                 original_case: @overturned_ico_foi_original,
                 identifier: "22B-original ico appeal for 18-overturned ico foi")
        @overturned_ico_foi =
          create :overturned_ico_foi,
                 responder: @responder,
                 responding_team: @responding_team,
                 original_case: @overturned_ico_foi_original,
                 original_ico_appeal: @overturned_ico_foi_original_appeal,
                 identifier: "22-overturned ico foi"

        @awaiting_responder_overturned_ico_foi_original =
          create(:closed_case,
                 responder: @responder,
                 responding_team: @responding_team,
                 identifier: "23A-original closed foi for 19-awaiting responder overturned ico foi")
        @awaiting_responder_overturned_ico_foi_original_appeal =
          create(:closed_ico_foi_case, :overturned_by_ico,
                 responder: @responder,
                 responding_team: @responding_team,
                 original_case: @awaiting_responder_overturned_ico_foi_original,
                 identifier: "23B-original ico appeal for 18-overturned ico foi")
        @awaiting_responder_overturned_ico_foi =
          create :awaiting_responder_ot_ico_foi,
                 responding_team: @responding_team,
                 original_case: @awaiting_responder_overturned_ico_foi_original,
                 original_ico_appeal: @awaiting_responder_overturned_ico_foi_original_appeal,
                 identifier: "23-awaiting responder overturned ico foi"

        @accepted_overturned_ico_foi_original =
          create(:closed_case,
                 responder: @responder,
                 responding_team: @responding_team,
                 identifier: "24A-original closed foi for 24-awaiting responder overturned ico foi")
        @accepted_overturned_ico_foi_original_appeal =
          create(:closed_ico_foi_case, :overturned_by_ico,
                 responder: @responder,
                 responding_team: @responding_team,
                 original_case: @accepted_overturned_ico_foi_original,
                 identifier: "24B-original ico appeal for 24-overturned ico foi")
        @accepted_overturned_ico_foi =
          create :accepted_ot_ico_foi,
                 responding_team: @responding_team,
                 original_case: @accepted_overturned_ico_foi_original,
                 original_ico_appeal: @accepted_overturned_ico_foi_original_appeal,
                 identifier: "24-accepted overturned ico foi"
        @closed_overturned_ico_foi =
          create :closed_ot_ico_foi,
                 responding_team: @responding_team,
                 original_case: @accepted_overturned_ico_foi_original,
                 original_ico_appeal: @accepted_overturned_ico_foi_original_appeal,
                 identifier: "25-closed overturned ico foi"
        @offender_sar =
          create :offender_sar_case,
                 identifier: "26-offender sar"
        @closed_offender_sar =
          create :offender_sar_case, :closed,
                 identifier: "27-closed offender sar"
        @offender_sar_complaint =
          create :offender_sar_complaint,
                 identifier: "28-offender sar complaint"
        @closed_offender_sar_complaint =
          create :offender_sar_complaint, :closed,
                 identifier: "29-closed offender sar complaint"
      end
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "#for_params" do
      it "filters cases for provided states" do
        finder = described_class.new(@manager)
        expect(finder.for_params("states" => "drafting").scope)
          .to match_array [@accepted_case, @accepted_overturned_ico_sar, @accepted_overturned_ico_foi]
      end
    end

    describe "#for_scopes" do
      it "applies the listed scopes" do
        finder = described_class.new(@manager)
        index_cases_scope_result = instance_double("IndexCasesScopeResult")
        allow(finder).to receive(:index_cases_scope)
                            .and_return(index_cases_scope_result)
        result = finder.for_scopes(%w[index_cases])
        expect(result).to be_a described_class
        expect(result.scope).to eq index_cases_scope_result
      end

      it "raises a NameError if a scope cannot be found" do
        finder = described_class.new(@manager)
        index_cases_scope_result = instance_double("IndexCasesScopeResult")
        allow(finder).to receive(:index_cases_scope)
                            .and_return(index_cases_scope_result)
        expect { finder.for_scopes(%w[index_cases missing_cases]) }
          .to raise_error NameError, "could not find scope named missing_cases_scope"
      end
    end

    describe "#new" do
      it "returns a finder scoped to the users cases" do
        expected = [
          @accepted_case,
          @accepted_overturned_ico_foi,
          @accepted_overturned_ico_foi_original,
          @accepted_overturned_ico_foi_original_appeal,
          @approved_ico,
          @approved_ico.original_case,
          @assigned_newer_case,
          @assigned_older_case,
          @assigned_other_team,
          @awaiting_responder_overturned_ico_foi,
          @awaiting_responder_overturned_ico_foi_original,
          @awaiting_responder_overturned_ico_foi_original_appeal,
          @case_1,
          @case_2,
          @closed_case_1,
          @closed_case_2,
          @closed_overturned_ico_foi,
          @newer_case_1,
          @newer_case_2,
          @newer_dacu_flagged_case,
          @newer_dacu_flagged_accept,
          @older_dacu_flagged_case,
          @closed_dacu_flagged_case,
          @older_dacu_flagged_accept,
          @older_case_1,
          @older_case_2,
          @overturned_ico_foi_original,
          @overturned_ico_foi_original_appeal,
          @overturned_ico_foi,
          @responded_ico,
          @responded_ico.original_case,
        ]

        finder = described_class.new(@responder)
        expect(finder.scope).to match_array expected
      end
    end

    describe "#index_cases_scope" do
      it "returns all the cases" do
        finder = described_class.new(@manager)
        expect(finder.__send__(:index_cases_scope))
          .to match_array [
            @accepted_case,
            @accepted_overturned_ico_foi,
            @accepted_overturned_ico_foi_original,
            @accepted_overturned_ico_foi_original_appeal,
            @accepted_overturned_ico_sar,
            @accepted_overturned_ico_sar_original,
            @accepted_overturned_ico_sar_original_appeal,
            @approved_ico,
            @approved_ico.original_case,
            @assigned_newer_case,
            @assigned_older_case,
            @assigned_other_team,
            @awaiting_responder_overturned_ico_foi,
            @awaiting_responder_overturned_ico_foi_original,
            @awaiting_responder_overturned_ico_foi_original_appeal,
            @awaiting_responder_overturned_ico_sar,
            @awaiting_responder_overturned_ico_sar_original,
            @awaiting_responder_overturned_ico_sar_original_appeal,
            @case_1,
            @case_2,
            @closed_case_1,
            @closed_case_2,
            @closed_overturned_ico_foi,
            @closed_overturned_ico_sar,
            @newer_case_1,
            @newer_case_2,
            @newer_dacu_flagged_case,
            @newer_dacu_flagged_accept,
            @older_dacu_flagged_case,
            @older_dacu_flagged_accept,
            @closed_dacu_flagged_case,
            @older_case_1,
            @older_case_2,
            @overturned_ico_foi_original,
            @overturned_ico_foi_original_appeal,
            @overturned_ico_foi,
            @overturned_ico_sar,
            @overturned_ico_sar_original,
            @overturned_ico_sar_original_appeal,
            @responded_ico,
            @responded_ico.original_case,
          ]
        expect(finder.__send__(:index_cases_scope))
          .not_to include @offender_sar
        expect(finder.__send__(:index_cases_scope))
          .not_to include @offender_sar_complaint
      end
    end

    describe "#closed_cases_scope" do
      it "returns closed cases" do
        finder = described_class.new(@manager)
        expect(finder.__send__(:closed_cases_scope))
          .to match_array [
            @closed_case_1,
            @closed_case_2,
            @responded_ico,
            @responded_ico.original_case,
            @approved_ico.original_case,
            @overturned_ico_sar_original,
            @overturned_ico_sar_original_appeal,
            @awaiting_responder_overturned_ico_sar_original,
            @awaiting_responder_overturned_ico_sar_original_appeal,
            @accepted_overturned_ico_sar_original,
            @accepted_overturned_ico_sar_original_appeal,
            @closed_overturned_ico_sar,
            @closed_dacu_flagged_case,
            @overturned_ico_foi_original,
            @overturned_ico_foi_original_appeal,
            @awaiting_responder_overturned_ico_foi_original,
            @awaiting_responder_overturned_ico_foi_original_appeal,
            @accepted_overturned_ico_foi_original,
            @accepted_overturned_ico_foi_original_appeal,
            @closed_overturned_ico_foi,
          ]
        expect(finder.__send__(:closed_cases_scope))
          .not_to include @offender_sar
        expect(finder.__send__(:index_cases_scope))
          .not_to include @offender_sar_complaint
      end
    end

    describe "#incoming_approving_cases_scope" do
      context "when a disclosure specialist" do
        it "returns incoming cases assigned to the users team" do
          finder = described_class.new(@disclosure_specialist)
          expect(finder.__send__(:incoming_approving_cases_scope))
            .to match_array [
              @older_dacu_flagged_case,
              @newer_dacu_flagged_case,
            ]
        end
      end
    end

    describe "#my_open_cases_scope" do
      context "when a disclosure specialist" do
        it "returns my open cases" do
          finder = described_class.new(@disclosure_specialist)
          expect(finder.__send__(:my_open_cases_scope))
            .to match_array [
              @approved_ico,
              @older_dacu_flagged_accept,
              @newer_dacu_flagged_accept,
            ]
        end
      end

      context "when a responder" do
        it "returns my open cases" do
          finder = described_class.new(@responder)
          expect(finder.__send__(:my_open_cases_scope))
            .to match_array [
              @accepted_case,
              @accepted_overturned_ico_foi,
              @approved_ico,
            ]
        end
      end
    end

    describe "#open_cases_scope" do
      let(:open_cases_general) do
        [
          @older_case_1,
          @older_case_2,
          @assigned_older_case,
          @older_dacu_flagged_case,
          @older_dacu_flagged_accept,
          @case_1,
          @case_2,
          @newer_case_1,
          @newer_case_2,
          @assigned_newer_case,
          @assigned_other_team,
          @newer_dacu_flagged_case,
          @newer_dacu_flagged_accept,
          @accepted_case,
          @approved_ico,
          @overturned_ico_sar,
          @awaiting_responder_overturned_ico_sar,
          @accepted_overturned_ico_sar,
          @overturned_ico_foi,
          @awaiting_responder_overturned_ico_foi,
          @accepted_overturned_ico_foi,
        ]
      end

      context "when non-responder" do
        let(:finder) { described_class.new(@manager) }

        it "returns all open cases except offender sar" do
          expect(finder.__send__(:open_cases_scope))
            .to match_array open_cases_general
        end

        it "does not return offender sar cases" do
          expect(finder.__send__(:open_cases_scope))
            .not_to include @offender_sar
          expect(finder.__send__(:index_cases_scope))
            .not_to include @offender_sar_complaint
        end
      end

      context "when normal responder" do
        let(:finder) { described_class.new(@responder) }

        it "returns all correct cases for user" do
          expect(finder.__send__(:open_cases_scope))
            .to match_array [
              @assigned_older_case,
              @assigned_newer_case,
              @awaiting_responder_overturned_ico_foi,
              @accepted_case,
              @accepted_overturned_ico_foi,
              @approved_ico,
            ]
        end

        it "does not return offender sar cases" do
          expect(finder.__send__(:open_cases_scope))
            .not_to include @offender_sar
          expect(finder.__send__(:index_cases_scope))
            .not_to include @offender_sar_complaint
        end
      end

      context "when branston-responder" do
        let(:finder) { described_class.new(@branston_responder) }

        it "returns all open offender sar cases" do
          expect(finder.__send__(:open_cases_scope))
            .to match_array [@offender_sar, @offender_sar_complaint]
        end

        it "does not return any non-offender sar cases" do
          found_cases = finder.__send__(:open_cases_scope)
          expect((found_cases & open_cases_general).empty?)
            .to be true
        end
      end
    end

    describe "#in_time_cases_scope" do
      it "returns all the cases that are in time" do
        Timecop.freeze(@case_1.external_deadline) do
          finder = described_class.new(@manager)
          expect(finder.__send__(:in_time_cases_scope))
            .to match_array [
              @case_1,
              @case_2,
              @newer_case_1,
              @newer_case_2,
              @assigned_newer_case,
              @assigned_other_team,
              @closed_case_1,
              @closed_case_2,
              @newer_dacu_flagged_case,
              @newer_dacu_flagged_accept,
              @accepted_case,
              @approved_ico,
              @responded_ico,
              @approved_ico.original_case,
              @responded_ico.original_case,
              @overturned_ico_sar_original,
              @overturned_ico_sar,
              @awaiting_responder_overturned_ico_sar_original,
              @awaiting_responder_overturned_ico_sar,
              @accepted_overturned_ico_sar,
              @accepted_overturned_ico_sar_original,
              @closed_overturned_ico_sar,
              @closed_dacu_flagged_case,
              @overturned_ico_foi_original,
              @overturned_ico_foi,
              @awaiting_responder_overturned_ico_foi_original,
              @awaiting_responder_overturned_ico_foi,
              @accepted_overturned_ico_foi,
              @accepted_overturned_ico_foi_original,
              @closed_overturned_ico_foi,
            ]

          expect(finder.__send__(:in_time_cases_scope))
              .not_to include @offender_sar
          expect(finder.__send__(:index_cases_scope))
              .not_to include @offender_sar_complaint
        end
      end
    end

    describe "#late_cases_scope" do
      it "returns all the cases that are late" do
        Timecop.freeze(@case_1.external_deadline) do
          finder = described_class.new(@manager)
          expect(finder.__send__(:late_cases_scope))
            .to match_array [
              @older_case_1,
              @older_case_2,
              @assigned_older_case,
              @older_dacu_flagged_case,
              @older_dacu_flagged_accept,
              @overturned_ico_sar_original_appeal,
              @awaiting_responder_overturned_ico_sar_original_appeal,
              @accepted_overturned_ico_sar_original_appeal,
              @overturned_ico_foi_original_appeal,
              @awaiting_responder_overturned_ico_foi_original_appeal,
              @accepted_overturned_ico_foi_original_appeal,
            ]
          expect(finder.__send__(:late_cases_scope))
              .not_to include @offender_sar
          expect(finder.__send__(:index_cases_scope))
              .not_to include @offender_sar_complaint
        end
      end
    end
  end

  context "with mix of FOI cases including compliance review cases" do
    before(:all) do
      @manager               = create :manager
      @responder             = find_or_create :foi_responder
      @press_officer         = find_or_create :press_officer
      @private_officer       = find_or_create :private_officer

      @disclosure_specialist = find_or_create :disclosure_specialist

      @responding_team      = @responder.responding_teams.first
      @team_dacu_disclosure = find_or_create :team_dacu_disclosure
      @managing_team        = find_or_create :managing_team

      Timecop.freeze(Date.new(2020, 8, 19)) do
        @foi_case_1                       = create :assigned_case,
                                                   creation_time: 2.business_days.ago,
                                                   identifier: "foi 1 case"
        @foi_case_2                       = create :assigned_case,
                                                   creation_time: 1.business_days.ago,
                                                   identifier: "foi 2 case"
        @foi_cr_case                      = create :accepted_compliance_review,
                                                   creation_time: 1.business_days.ago
        @foi_tr_case                      = create :accepted_timeliness_review,
                                                   creation_time: 1.business_days.ago
        @awaiting_responder_ot_ico_foi    = create :awaiting_responder_ot_ico_foi,
                                                   creation_time: 1.business_days.ago
        @awaiting_responder_ot_ico_foi.update!(escalation_deadline: 3.days.from_now)
      end
    end

    after(:all) do
      DbHousekeeping.clean(seed: true)
    end

    describe "#incoming_cases_press_office_scope" do
      it "returns incoming non-review cases ordered by creation date descending" do
        finder = described_class.new(@press_officer)
        Timecop.freeze(Date.new(2020, 8, 19)) do
          expect(finder.__send__(:incoming_cases_press_office_scope))
            .to match_array [@foi_case_2, @foi_case_1, @awaiting_responder_ot_ico_foi]
        end
      end

      it "does not return internal review cases" do
        finder = described_class.new(@press_officer)
        Timecop.freeze(Date.new(2020, 8, 19)) do
          expect(finder.__send__(:incoming_cases_press_office_scope))
            .to match_array [@foi_case_1, @foi_case_2, @awaiting_responder_ot_ico_foi]
        end
      end

      context "when internal review case has received request for further clearance" do
        before do
          @foi_cr_case.state_machine.request_further_clearance!(
            acting_user: @manager,
            acting_team: @managing_team,
            target_user: @foi_cr_case.responder,
            target_team: @foi_cr_case.responding_team,
          )
          @foi_tr_case.state_machine.request_further_clearance!(
            acting_user: @manager,
            acting_team: @managing_team,
            target_user: @foi_tr_case.responder,
            target_team: @foi_tr_case.responding_team,
          )
        end

        it "does return the case" do
          finder = described_class.new(@press_officer)
          Timecop.freeze(Date.new(2020, 8, 19)) do
            expect(finder.__send__(:incoming_cases_press_office_scope))
              .to match_array [@foi_case_1, @foi_case_2, @foi_cr_case, @foi_tr_case, @awaiting_responder_ot_ico_foi]
          end
        end
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
