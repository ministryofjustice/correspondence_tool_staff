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

    @closed_case_1        = create(:closed_case, received_date: dd(17))
    @older_case_1         = create(:case, received_date: dd(15), subject: 'older request 1')
    @newer_case_1         = create(:case, received_date: dd(17), subject: 'newer request 1')
    @case_1               = create(:case, received_date: dd(16), subject: 'request 1')
    @case_2               = create(:case, received_date: dd(16), subject: 'request 2')
    @newer_case_2         = create(:case, received_date: dd(17), subject: 'newer request 2')
    @older_case_2         = create(:case, received_date: dd(15), subject: 'older request 2')
    @closed_case_2        = create(:closed_case)

    @assigned_newer_case  = create(:awaiting_responder_case, received_date: dd(17), responding_team: @responding_team, subject: 'new assigned case')
    @assigned_older_case  = create(:awaiting_responder_case, received_date: dd(15), responding_team: @responding_team, subject: 'old assigned case')
    @assigned_other_team  = create(:awaiting_responder_case, received_date: dd(17), subject: 'assigned other team')

    @newer_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(17), subject: 'newer_flagged_case')
    @older_flagged_case   = create(:case, :flagged, approving_team: @approving_team, received_date: dd(15), subject: 'newer_flagged_case')
    @newer_flagged_accept = create(:case, :flagged_accepted, received_date: dd(17), approving_team: @approving_team, approver: @approver, subject: 'newer flagged accepted')
    @older_flagged_accept = create(:case, :flagged_accepted, received_date: dd(15), approving_team: @approving_team, approver: @approver, subject: 'older flagged accepted')
    @other_flagged_case   = create(:case, :flagged, received_date: dd(16))
  end

  after(:all) { DbHousekeeping.clean }

  def dd(n)
    Date.new(2016, 11, n)
  end

  describe 'index action' do
    context 'as a manager' do
      it 'returns all open cases ordered by external deadline, then id' do
        cases = CaseFinderService.new(@manager, :index).cases
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
        cases = CaseFinderService.new(@responder, :index).cases
        expect(cases).to eq CaseDecorator.decorate_collection([ @assigned_older_case, @assigned_newer_case ])
      end
    end

    context 'as an approver' do
      it 'returns all the cases flagged and accepted by my team' do
        cases = CaseFinderService.new(@approver, :index).cases
        expect(cases).to eq CaseDecorator.decorate_collection([ @older_flagged_accept, @newer_flagged_accept ])
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
