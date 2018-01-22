require 'rails_helper'

describe CaseFinderService do
  def dd(n)
    Date.new(2016, 11, n)
  end

  let(:empty_collection) { CaseDecorator.decorate_collection(Array.new)}

  context 'cases for responders and flagged dacu disclosure' do
    before(:all) do
      Timecop.freeze Date.new(2016, 11, 25) do
        @manager               = create :manager
        @responder             = create :responder

        @disclosure_specialist = create :disclosure_specialist

        @responding_team      = @responder.responding_teams.first
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure
        @managing_team        = find_or_create :managing_team

        @closed_case_1        = create(:closed_case, :granted_in_full,
                                       received_date: dd(17),
                                       date_responded: dd(22),
                                       identifier: 'closed case 1')
        @older_case_1         = create(:case,
                                       received_date: dd(15),
                                       identifier: 'older case 1')
        @newer_case_1         = create(:case,
                                       received_date: dd(17),
                                       identifier: 'newer case 1')
        @case_1               = create(:case,
                                       received_date: dd(16),
                                       identifier: 'case 1')
        @case_2               = create(:case,
                                       received_date: dd(16),
                                       identifier: 'case 2')
        @newer_case_2         = create(:case,
                                       received_date: dd(17),
                                       identifier: 'newer case 2')
        @older_case_2         = create(:case,
                                       received_date: dd(15),
                                       identifier: 'older case 2')
        @closed_case_2        = create(:closed_case, :granted_in_full,
                                       received_date: dd(15),
                                       date_responded: dd(23),
                                       identifier: 'closed case 2')
        @assigned_newer_case  = create(:awaiting_responder_case,
                                       received_date: dd(17),
                                       responding_team: @responding_team,
                                       identifier: 'assigned newer case')
        @assigned_older_case  = create(:awaiting_responder_case,
                                       received_date: dd(15),
                                       responding_team: @responding_team,
                                       identifier: 'old assigned case')
        @assigned_other_team  = create(:awaiting_responder_case,
                                       received_date: dd(17),
                                       identifier: 'assigned other team')
        @newer_dacu_flagged_case   = create(:case, :flagged, :dacu_disclosure,
                                            received_date: dd(17),
                                            identifier: 'newer flagged case')
        @older_dacu_flagged_case   = create(:case, :flagged, :dacu_disclosure,
                                            received_date: dd(15),
                                            identifier: 'older flagged case')
        @newer_dacu_flagged_accept =
          create(:case, :flagged_accepted, :dacu_disclosure,
                 received_date: dd(17),
                 approver: @disclosure_specialist,
                 identifier: 'newer dacu flagged accept')
        @older_dacu_flagged_accept =
          create(:case, :flagged_accepted, :dacu_disclosure,
                 received_date: dd(15),
                 approver: @disclosure_specialist,
                 identifier: 'older dacu flagged accept')
        @accepted_case        = create(:accepted_case,
                                       responder: @responder)
      end
    end

    after(:all) { DbHousekeeping.clean }

    describe '#for_params' do
      it 'filters cases for provided states' do
        finder = CaseFinderService.new(@manager)
        expect(finder.for_params('states' => 'drafting').scope)
          .to match_array [@accepted_case]
      end
    end

    describe '#for_scopes' do
      it 'applies the listed scopes' do
        finder = CaseFinderService.new(@manager)
        index_cases_scope_result = double('IndexCasesScopeResult')
        expect(finder).to receive(:index_cases_scope)
                            .and_return(index_cases_scope_result)
        result = finder.for_scopes(['index_cases'])
        expect(result).to be_a CaseFinderService
        expect(result.scope).to eq index_cases_scope_result
      end

      it 'raises a NameError if a scope cannot be found' do
        finder = CaseFinderService.new(@manager)
        index_cases_scope_result = double('IndexCasesScopeResult')
        expect(finder).to receive(:index_cases_scope)
                            .and_return(index_cases_scope_result)
        expect { finder.for_scopes(['index_cases', 'missing_cases']) }
          .to raise_error NameError, 'could not find scope named missing_cases_scope'
      end
    end

    describe '#for_user' do
      it 'returns a finder that with a finder scoped to the users cases' do
        finder = CaseFinderService.new(@responder)
        expect(finder.for_user.scope).to match_array [
                                           @assigned_newer_case,
                                           @assigned_older_case,
                                           @accepted_case
                                         ]
      end
    end

    describe '#index_cases_scope' do
      it 'returns all the cases' do
        finder = CaseFinderService.new(@manager)
        expect(finder.__send__ :index_cases_scope)
          .to match_array [
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
                @closed_case_1,
                @closed_case_2,
                @newer_dacu_flagged_case,
                @newer_dacu_flagged_accept,
                @accepted_case,
              ]
      end
    end

    describe '#closed_cases_scope' do
      it 'returns closed cases' do
        finder = CaseFinderService.new(@manager)
        expect(finder.__send__ :closed_cases_scope)
          .to eq [
                @closed_case_1,
                @closed_case_2,
              ]
      end
    end

    describe '#incoming_approving_cases_scope' do
      context 'as a disclosure specialist' do
        it 'returns incoming cases assigned to the users team' do
          finder = CaseFinderService.new(@disclosure_specialist)
          expect(finder.__send__ :incoming_approving_cases_scope)
            .to match_array [
                  @older_dacu_flagged_case,
                  @newer_dacu_flagged_case
                ]
        end
      end
    end

    describe '#my_open_cases_scope' do
      context 'as a disclosure specialist' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@disclosure_specialist)
          expect(finder.__send__ :my_open_cases_scope)
            .to match_array [
                  @older_dacu_flagged_accept,
                  @newer_dacu_flagged_accept
                ]
        end
      end

      context 'as a responder' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@responder)
          expect(finder.__send__ :my_open_cases_scope)
            .to match_array [
                  @accepted_case
                ]
        end
      end
    end

    describe '#open_cases_scope' do
      it 'returns all open cases' do
        finder = CaseFinderService.new(@manager)
        expect(finder.__send__ :open_cases_scope)
          .to match_array [
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
              ]
      end
    end

    describe '#in_time_cases_scope' do
      it 'returns all the cases that are in time' do
        Timecop.freeze(@case_1.external_deadline) do
          finder = CaseFinderService.new(@manager)
          expect(finder.__send__ :in_time_cases_scope)
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
                ]
        end
      end
    end

    describe '#late_cases_scope' do
      it 'returns all the cases that are late' do
        Timecop.freeze(@case_1.external_deadline) do
          finder = CaseFinderService.new(@manager)
          expect(finder.__send__ :late_cases_scope)
            .to match_array [
                  @older_case_1,
                  @older_case_2,
                  @assigned_older_case,
                  @older_dacu_flagged_case,
                  @older_dacu_flagged_accept,
                ]
        end
      end
    end

  end

  context 'mix of FOI cases including compliance review cases' do
    before(:all) do
      @manager               = create :manager
      @responder             = create :responder
      @press_officer         = create :press_officer
      @private_officer       = create :private_officer

      @disclosure_specialist = create :disclosure_specialist

      @responding_team      = @responder.responding_teams.first
      @team_dacu_disclosure = find_or_create :team_dacu_disclosure
      @managing_team        = find_or_create :managing_team

      @foi_case_1           = create :assigned_case,
                                     creation_time: 2.business_days.ago,
                                     identifier: 'foi 1 case'
      @foi_case_2           = create :assigned_case,
                                     creation_time: 1.business_days.ago,
                                     identifier: 'foi 2 case'
      @foi_cr_case          = create :accepted_compliance_review,
                                     creation_time: 1.business_days.ago
      @foi_tr_case          = create :accepted_timeliness_review,
                                     creation_time: 1.business_days.ago
    end

    after(:all) {DbHousekeeping.clean}

    describe '#incoming_cases_press_office_scope' do
      it 'returns incoming non-review cases ordered by creation date descending' do
        finder = CaseFinderService.new(@press_officer)
        expect(finder.__send__ :incoming_cases_press_office_scope)
          .to eq [@foi_case_2, @foi_case_1]
      end

      it 'does not return internal review cases' do
        finder = CaseFinderService.new(@press_officer)
        expect(finder.__send__ :incoming_cases_press_office_scope)
          .to match_array [ @foi_case_1, @foi_case_2 ]
      end

      context 'internal review case has received request for further clearance' do
        before do
          @foi_cr_case.state_machine.request_further_clearance!(
            acting_user: @manager,
            acting_team: @managing_team,
          )
          @foi_tr_case.state_machine.request_further_clearance!(
            acting_user: @manager,
            acting_team: @managing_team,
          )
        end

        it 'does return the case' do
          finder = CaseFinderService.new(@press_officer)
          expect(finder.__send__ :incoming_cases_press_office_scope)
            .to match_array [ @foi_case_1, @foi_case_2, @foi_cr_case, @foi_tr_case ]
        end
      end
    end
  end

  context 'cases flagged for press office' do
    let!(:too_old_case)       { create(:case,
                                       created_at: 4.business_days.ago,
                                       identifier: 'older case') }
    let!(:old_case)           { create(:case,
                                       created_at: 3.business_days.ago,
                                       identifier: 'old case') }
    let!(:new_case)           { create(:case,
                                       received_date: 1.business_days.ago,
                                       created_at: 1.business_days.ago,
                                       identifier: 'new case') }
    let!(:too_new_case)       { create(:case, identifier: 'fresh case') }
    let!(:press_flagged_case) { create(:case, :flagged_accepted, :press_office,
                                       identifier: 'fresh press flagged case') }

    let(:press_officer) { create :press_officer }

    describe 'incoming_cases_press_office filter' do
    end
  end
end
