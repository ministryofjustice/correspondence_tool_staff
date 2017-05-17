require 'rails_helper'

describe CaseFinderService do

  let(:d1711) { Date.new(2016, 11, 17) }
  let(:d1611) { Date.new(2016, 11, 16) }
  let(:d1511) { Date.new(2016, 11, 15) }
  let(:empty_collection) { CaseDecorator.decorate_collection(Array.new)}

  before(:all) do
    @manager              = create :manager
    @responder            = create :responder
    @approver             = create :approver

    @responding_team      = @responder.responding_teams.first
    @approving_team       = @approver.approving_teams.first

    @closed_case_1        = create(:closed_case, received_date: dd(17), identifier: 'closed case 1')
    @older_case_1         = create(:case, received_date: dd(15), identifier: 'older request 1')
    @newer_case_1         = create(:case, received_date: dd(17), identifier: 'newer request 1')
    @case_1               = create(:case, received_date: dd(16), identifier: 'request 1')
    @case_2               = create(:case, received_date: dd(16), identifier: 'request 2')
    @newer_case_2         = create(:case, received_date: dd(17), identifier: 'newer request 2')
    @older_case_2         = create(:case, received_date: dd(15), identifier: 'older request 2')
    @closed_case_2        = create(:closed_case, identifier: 'closed case 2')

    @assigned_newer_case  = create(:awaiting_responder_case, received_date: dd(17), responding_team: @responding_team, identifier: 'new assigned case')
    @assigned_older_case  = create(:awaiting_responder_case, received_date: dd(15), responding_team: @responding_team, identifier: 'old assigned case')
    @assigned_other_team  = create(:awaiting_responder_case, received_date: dd(17), identifier: 'assigned other team')

    @newer_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(17), identifier: 'newer flagged case')
    @older_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(15), identifier: 'older flagged case')
    @newer_flagged_accept = create(:case, :flagged_accepted, received_date: dd(17), approving_team: @approving_team, approver: @approver, identifier: 'newer flagged accepted')
    @older_flagged_accept = create(:case, :flagged_accepted, received_date: dd(15), approving_team: @approving_team, approver: @approver, identifier: 'older flagged accepted')
    @other_flagged_case   = create(:case, :flagged, received_date: dd(16), identifier: 'other flagged case')
  end

  after(:all) { DbHousekeeping.clean }

  def dd(n)
    Date.new(2016, 11, n)
  end

  describe '#index_cases' do
    context 'as a manager' do
      it 'returns all the cases the user is allowed to view' do
        cases = CaseFinderService.new(@manager, :index).cases
        expect(cases).to match_array CaseDecorator.decorate_collection(
          [
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
            @newer_flagged_accept
          ])
      end
    end

    context 'as a responder' do
      it 'returns all open cases assigned to my team ordered by external deadline, then id' do
        cases = CaseFinderService.new(@responder, :index).cases
        expect(cases)
          .to match_array CaseDecorator
                            .decorate_collection([ @assigned_older_case,
                                                   @assigned_newer_case ])
      end
    end

    context 'as an approver' do
      it 'returns all the cases flagged and accepted by my team' do
        cases = CaseFinderService.new(@approver, :index).cases
        expect(cases)
          .to match_array CaseDecorator
                            .decorate_collection([ @newer_flagged_case,
                                                   @older_flagged_case,
                                                   @older_flagged_accept,
                                                   @newer_flagged_accept])
      end
    end
  end

  describe '#open_cases' do
    context 'as a manager' do
      it 'returns all open cases ordered by external deadline, then id' do
        cases = CaseFinderService.new(@manager, :open_cases).cases
        expect(cases).to eq CaseDecorator.decorate_collection(
          [
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
            @newer_flagged_accept
          ])
      end
    end

    context 'as a responder' do
      it 'returns all open cases assigned to my team ordered by external deadline, then id' do
        cases = CaseFinderService.new(@responder, :open_cases).cases
        expect(cases)
          .to eq CaseDecorator.decorate_collection([ @assigned_older_case,
                                                     @assigned_newer_case ])
      end
    end

    context 'as an approver' do
      it 'returns all the cases flagged and accepted by my team' do
        cases = CaseFinderService.new(@approver, :open_cases).cases
        expect(cases)
          .to eq CaseDecorator.decorate_collection([ @older_flagged_accept,
                                                     @newer_flagged_accept ])
      end
    end
  end

  describe 'incoming_cases action' do
    context 'as an approver' do
      it 'returns all unaccepted cases flagged for my team' do
        cases = CaseFinderService.new(@approver, :incoming_cases).cases
        expect(cases).to eq CaseDecorator.decorate_collection([ @older_flagged_case, @newer_flagged_case])
      end
    end

  end

  describe 'closed_cases action' do
    context 'as a manager' do
      it 'returns all closed cases most recent first' do
        cases = CaseFinderService.new(@manager, :closed_cases).cases
        expect(cases).to eq CaseDecorator.decorate_collection([ @closed_case_2, @closed_case_1 ])
      end
    end

    context 'as a responder' do
      it 'returns all closed cases for users team most recent first' do
        cases = CaseFinderService.new(@responder, :closed_cases).cases
        expect(cases).to eq empty_collection
      end
    end

    context 'as an approver' do
      it 'returns all closed cases for users team most recent first' do
        cases = CaseFinderService.new(@approver, :closed_cases).cases
        expect(cases).to eq empty_collection
      end
    end
  end
end
