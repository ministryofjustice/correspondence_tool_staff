require 'rails_helper'

describe CaseFinderService do

  let(:empty_collection) { CaseDecorator.decorate_collection(Array.new)}

  context 'cases for responders and flagged dacu disclosure' do
    def dd(n)
      Date.new(2016, 11, n)
    end

    before(:all) do
      Timecop.freeze Date.new(2016, 11, 25) do
        @manager               = create :manager
        @responder             = create :responder

        @disclosure_specialist = create :disclosure_specialist

        @responding_team      = @responder.responding_teams.first
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure

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

    describe '#filter_for_params' do
      context 'params specify state' do
        it 'filters cases for provided states' do
          finder = CaseFinderService.new(@manager,
                                         ['index_cases'],
                                         { 'states' => 'drafting' })
          expect(finder.cases).to match_array [@accepted_case]
        end
      end
    end

    describe 'apply_filter' do
      it 'applies the listed filters' do

      end
    end

    describe 'index_case filter' do
      it 'returns all the cases' do
        expect(CaseFinderService.new(@manager, ['index_cases'], {}).cases)
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

    describe 'closed_cases filter' do
      it 'returns closed cases' do
        finder = CaseFinderService.new(@manager, ['closed_cases'], {})
        expect(finder.cases)
          .to eq [
                @closed_case_1,
                @closed_case_2,
              ]
      end
    end

    describe 'incoming_cases_dacu_disclosure filter' do
      context 'as a disclosure specialist' do
        it 'returns incoming cases' do
          finder = CaseFinderService.new(@disclosure_specialist,
                                         ['incoming_cases_dacu_disclosure'],
                                         {})
          expect(finder.cases) .to match_array [
                                     @older_dacu_flagged_case,
                                     @newer_dacu_flagged_case
                                   ]
        end
      end
    end

    describe 'my_open_cases filter' do
      context 'as a disclosure specialist' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@disclosure_specialist,
                                         ['my_open_cases'],
                                         {})
          expect(finder.cases).to eq [ @older_dacu_flagged_accept,
                                       @newer_dacu_flagged_accept, ]
        end
      end

      context 'as a responder' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@responder,
                                         ['my_open_cases'],
                                         {})
          expect(finder.cases).to eq [ @accepted_case, ]
        end
      end
    end

    describe 'open_cases filter' do
      context 'as a manager' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@manager,
                                         ['open_cases'],
                                         {})
          expect(finder.cases).to eq [
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

      context 'as a disclosure specialist' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@disclosure_specialist,
                                         ['open_cases'],
                                         {})
          expect(finder.cases).to eq [
                                    @older_dacu_flagged_accept,
                                    @newer_dacu_flagged_accept
                                  ]
        end
      end

      context 'as a responder' do
        it 'returns my open cases' do
          finder = CaseFinderService.new(@responder,
                                         ['open_cases'],
                                         {})
          expect(finder.cases).to eq [
                                    @assigned_older_case,
                                    @assigned_newer_case,
                                    @accepted_case,
                                  ]
        end
      end
    end

    describe 'in_time filter' do
      it 'returns all the cases that are in time' do
        Timecop.freeze(@case_1.external_deadline) do
          finder = CaseFinderService.new(@manager,
                                         ['in_time'],
                                         {})
          expect(finder.cases).to match_array [
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

    describe 'late filter' do
      it 'returns all the cases that are late' do
        Timecop.freeze(@case_1.external_deadline) do
          finder = CaseFinderService.new(@manager,
                                         ['late'],
                                         {})
          expect(finder.cases).to match_array [
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

    context 'as a press officer' do
      describe 'incoming_cases_press_office filter' do
        it 'returns incoming cases ordered by creation date' do
          finder = CaseFinderService.new(press_officer,
                                         ['incoming_cases_press_office'],
                                         {})
          expect(finder.cases).to eq [new_case, old_case]
        end
      end

      describe 'open_cases filter' do
        it 'returns incoming cases ordered by creation date' do
          finder = CaseFinderService.new(press_officer,
                                         ['open_cases'],
                                         {})
          expect(finder.cases).to eq [press_flagged_case]
        end
      end
    end
  end
end
