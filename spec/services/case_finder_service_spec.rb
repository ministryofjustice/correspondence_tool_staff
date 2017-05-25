require 'rails_helper'

describe CaseFinderService do

  let(:d1711) { Date.new(2016, 11, 17) }
  let(:d1611) { Date.new(2016, 11, 16) }
  let(:d1511) { Date.new(2016, 11, 15) }
  let(:empty_collection) { CaseDecorator.decorate_collection(Array.new)}

  before(:all) do
    Timecop.freeze Date.new(2016, 11, 25) do
      @manager              = create :manager
      @responder            = create :responder
      @approver             = create :approver

      @responding_team      = @responder.responding_teams.first
      @approving_team       = @approver.approving_teams.first

      @closed_case_1        = create(:closed_case, received_date: dd(17), date_responded: dd(22), identifier: 'closed case 1')
      @older_case_1         = create(:case, received_date: dd(15), identifier: 'older request 1')
      @newer_case_1         = create(:case, received_date: dd(17), identifier: 'newer request 1')
      @case_1               = create(:case, received_date: dd(16), identifier: 'request 1')
      @case_2               = create(:case, received_date: dd(16), identifier: 'request 2')
      @newer_case_2         = create(:case, received_date: dd(17), identifier: 'newer request 2')
      @older_case_2         = create(:case, received_date: dd(15), identifier: 'older request 2')
      @closed_case_2        = create(:closed_case, received_date: dd(15), date_responded: dd(23), identifier: 'closed case 2')

      @assigned_newer_case  = create(:awaiting_responder_case, received_date: dd(17), responding_team: @responding_team, identifier: 'new assigned case')
      @assigned_older_case  = create(:awaiting_responder_case, received_date: dd(15), responding_team: @responding_team, identifier: 'old assigned case')
      @assigned_other_team  = create(:awaiting_responder_case, received_date: dd(17), identifier: 'assigned other team')

      @newer_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(17), identifier: 'newer flagged case')
      @older_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(15), identifier: 'older flagged case')
      @newer_flagged_accept = create(:case, :flagged_accepted, received_date: dd(17), approving_team: @approving_team, approver: @approver, identifier: 'newer flagged accepted')
      @older_flagged_accept = create(:case, :flagged_accepted, received_date: dd(15), approving_team: @approving_team, approver: @approver, identifier: 'older flagged accepted')
      @other_flagged_case   = create(:case, :flagged, received_date: dd(16), identifier: 'other flagged case')
      @accepted_case        = create(:accepted_case, responder: @responder)
    end
  end

  after(:all) { DbHousekeeping.clean }

  def dd(n)
    Date.new(2016, 11, n)
  end

  describe '#for_action' do
    let(:finder) do
      cfs = CaseFinderService.new
      allow(cfs).to receive(:index_cases).and_return(:called_index_cases)
      allow(cfs).to receive(:closed_cases).and_return(:called_closed_cases)
      allow(cfs).to receive(:incoming_cases).and_return(:called_incoming_cases)
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

    it 'calls the incoming filter' do
      expect(finder.for_action(:incoming_cases)).to eq :called_incoming_cases
      expect(finder).to have_received(:incoming_cases)
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
              @older_flagged_case,
              @older_flagged_accept,
              @case_1,
              @case_2,
              @other_flagged_case,
              @newer_case_1,
              @newer_case_2,
              @assigned_newer_case,
              @assigned_other_team,
              @closed_case_1,
              @closed_case_2,
              @newer_flagged_case,
              @newer_flagged_accept,
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

  describe '#incoming_cases' do
    context 'as an approver' do
      let(:finder) { CaseFinderService.new.for_user(@approver) }

      it 'returns incoming cases' do
        expect(finder.incoming_cases.cases)
          .to eq [
                @older_flagged_case,
                @newer_flagged_case
              ]
      end
    end
  end

  describe '#my_open_cases' do
    context 'as an approver' do
      let(:finder) { CaseFinderService.new.for_user(@approver) }

      it 'returns my open cases' do
        expect(finder.my_open_cases.cases)
          .to eq [
                @older_flagged_accept,
                @newer_flagged_accept,
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
                @older_flagged_case,
                @older_flagged_accept,
                @case_1,
                @case_2,
                @other_flagged_case,
                @newer_case_1,
                @newer_case_2,
                @assigned_newer_case,
                @assigned_other_team,
                @newer_flagged_case,
                @newer_flagged_accept,
                @accepted_case,
              ]
      end
    end

    context 'as an approver' do
      let(:finder) { CaseFinderService.new.for_user(@approver) }

      it 'returns my open cases' do
        expect(finder.open_cases.cases)
          .to eq [
                @older_flagged_accept,
                @newer_flagged_accept
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

  fdescribe '#timeliness' do
    describe 'in_time' do
      it 'returns all the cases that are in time' do
        Timecop.freeze(@case_1.external_deadline) do
          expect(CaseFinderService.new.timeliness('in_time').cases)
            .to match_array [
                  @case_1,
                  @case_2,
                  @other_flagged_case,
                  @newer_case_1,
                  @newer_case_2,
                  @assigned_newer_case,
                  @assigned_other_team,
                  @closed_case_1,
                  @closed_case_2,
                  @newer_flagged_case,
                  @newer_flagged_accept,
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
                  @older_flagged_case,
                  @older_flagged_accept,
                ]
        end
      end
    end
  end
end
