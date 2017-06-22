require 'rails_helper'

describe CaseFinderService do

  let(:empty_collection) { CaseDecorator.decorate_collection(Array.new)}

  context 'cases for responders and flagged dacu disclosure' do
    def dd(n)
      Date.new(2016, 11, n)
    end

    describe '#for_action' do
      let(:finder) do
        cfs = CaseFinderService.new
        allow(cfs).to receive(:index_cases).and_return(:called_index_cases)
        allow(cfs).to receive(:closed_cases).and_return(:called_closed_cases)
        allow(cfs).to receive(:incoming_cases_dacu_disclosure)
                        .and_return(:called_dacu_disclosure_incoming_cases)
        allow(cfs).to receive(:incoming_cases_press_office)
                        .and_return(:called_press_office_incoming_cases)
        allow(cfs).to receive(:my_open_cases).and_return(:called_my_open_cases)
        allow(cfs).to receive(:open_cases).and_return(:called_open_cases)
        cfs
      end

      it 'calls the index filter' do
        expect(finder.for_action(:index)).to eq :called_index_cases
        expect(finder).to have_received(:index_cases)
      end

      it 'calls the closed filter' do
        expect(finder.for_action(:closed_cases)).to eq :called_closed_cases
        expect(finder).to have_received(:closed_cases)
      end

      it 'calls the DACU Disclosure incoming filter' do
        expect(finder.for_action(:incoming_cases_dacu_disclosure))
          .to eq :called_dacu_disclosure_incoming_cases
        expect(finder).to have_received(:incoming_cases_dacu_disclosure)
      end

      it 'calls the Press Office incoming filter' do
        expect(finder.for_action(:incoming_cases_press_office))
          .to eq :called_press_office_incoming_cases
        expect(finder).to have_received(:incoming_cases_press_office)
      end

      it 'calls the my_open filter' do
        expect(finder.for_action(:my_open_cases)).to eq :called_my_open_cases
        expect(finder).to have_received(:my_open_cases)
      end

      it 'calls the open filter' do
        expect(finder.for_action(:open_cases)).to eq :called_open_cases
        expect(finder).to have_received(:open_cases)
      end
    end

    before(:all) do
      Timecop.freeze Date.new(2016, 11, 25) do
        @manager               = create :manager
        @responder             = create :responder
        @disclosure_specialist = create :disclosure_specialist

        @responding_team      = @responder.responding_teams.first
        @team_dacu_disclosure = find_or_create :team_dacu_disclosure

        @closed_case_1        = create(:closed_case,
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
        @closed_case_2        = create(:closed_case,
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
      context 'params specify timeliness' do
        let(:params) { { timeliness: 'in_time' } }
        let(:finder) do
          cfs = CaseFinderService.new
          allow(cfs).to receive(:timeliness).and_return(:called_timeliness)
          cfs
        end

        it 'calls timeliness' do
          expect(finder.filter_for_params(params)).to eq :called_timeliness
          expect(finder).to have_received(:timeliness)
        end
      end
    end

    describe '#index_cases' do
      it 'returns all the cases' do
        expect(CaseFinderService.new.index_cases.cases)
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

    describe '#closed_cases' do
      it 'returns closed cases' do
        expect(CaseFinderService.new.closed_cases.cases)
          .to eq [
                @closed_case_1,
                @closed_case_2,
              ]
      end
    end

    describe '#incoming_cases_dacu_disclosure' do
      context 'as a disclosure specialist' do
        let(:finder) { CaseFinderService.new.for_user(@disclosure_specialist) }

        it 'returns incoming cases' do
          expect(finder.incoming_cases_dacu_disclosure.cases)
            .to eq [
                  @older_dacu_flagged_case,
                  @newer_dacu_flagged_case
                ]
        end
      end
    end

    describe '#my_open_cases' do
      context 'as a disclosure specialist' do
        let(:finder) { CaseFinderService.new.for_user(@disclosure_specialist) }

        it 'returns my open cases' do
          expect(finder.my_open_cases.cases)
            .to eq [
                  @older_dacu_flagged_accept,
                  @newer_dacu_flagged_accept,
                ]
        end
      end

      context 'as a responder' do
        let(:finder) { CaseFinderService.new.for_user(@responder) }

        it 'returns my open cases' do
          expect(finder.my_open_cases.cases)
            .to eq [
                  @accepted_case,
                ]
        end
      end
    end

    describe '#open_cases' do
      context 'as a manager' do
        let(:finder) { CaseFinderService.new.for_user(@manager) }

        it 'returns my open cases' do
          expect(finder.open_cases.cases)
            .to eq [
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
        let(:finder) { CaseFinderService.new.for_user(@disclosure_specialist) }

        it 'returns my open cases' do
          expect(finder.open_cases.cases)
            .to eq [
                  @older_dacu_flagged_accept,
                  @newer_dacu_flagged_accept
                ]
        end
      end

      context 'as a responder' do
        let(:finder) { CaseFinderService.new.for_user(@responder) }

        it 'returns my open cases' do
          expect(finder.open_cases.cases)
            .to eq [
                  @assigned_older_case,
                  @assigned_newer_case,
                  @accepted_case,
                ]
        end
      end
    end

    describe '#timeliness' do
      describe 'in_time' do
        it 'returns all the cases that are in time' do
          Timecop.freeze(@case_1.external_deadline) do
            expect(CaseFinderService.new.timeliness('in_time').cases)
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

      describe 'late' do
        it 'returns all the cases that are late' do
          Timecop.freeze(@case_1.external_deadline) do
            expect(CaseFinderService.new.timeliness('late').cases)
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
      let(:finder) { CaseFinderService.new.for_user(press_officer) }

      describe '#incoming_cases_press_office' do
        it 'returns incoming cases ordered by creation date' do
          expect(finder.incoming_cases_press_office.cases)
            .to eq [new_case, old_case]
        end
      end

      describe '#open_cases' do
        it 'returns incoming cases ordered by creation date' do
          expect(finder.open_cases.cases).to eq [press_flagged_case]
        end
      end
    end
  end
end
