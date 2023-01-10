require 'rails_helper'

RSpec.describe Case::OverturnedICO::FOIPolicy do
  subject { described_class }

  let(:managing_team)         { find_or_create :team_dacu }
  let(:other_managing_team)   { create :managing_team }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { dacu_disclosure.approvers.first }

  let(:unassigned_case)       { create :overturned_ico_foi }

  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { find_or_create :responder }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }

  it 'inherits from the SAR policy' do
    expect(described_class.ancestors).to include Case::FOI::StandardPolicy
  end

  permissions :can_add_case? do
    it { should     permit(manager,                 Case::OverturnedICO::FOI) }
    it { should_not permit(disclosure_specialist,   Case::OverturnedICO::FOI) }
    it { should_not permit(responder,               Case::OverturnedICO::FOI) }
  end

  permissions :new? do
    context 'manager' do
      it { should permit(manager, Case::OverturnedICO::Base) }
    end

    context 'responder' do
      it { should_not permit(responder, Case::OverturnedICO::Base) }
    end

    context 'approver' do
      it { should_not permit(disclosure_specialist, Case::OverturnedICO::Base) }
    end
  end


  permissions :show? do
    context 'unassigned case' do
      it { should     permit(manager,               unassigned_case) }
      it { should     permit(responder,             unassigned_case) }
      it { should     permit(disclosure_specialist, unassigned_case) }
    end
  end

  permissions :new_case_link? do
    it { should     permit(manager,             unassigned_case) }
    it { should_not permit(other_manager,       unassigned_case) }
    it { should_not permit(responder,           unassigned_case) }
    it { should_not permit(press_officer,       unassigned_case) }
    it { should_not permit(private_officer,     unassigned_case) }
    it { should_not permit(disclosure_approver, unassigned_case) }
  end

  describe 'request_further_clearance?' do
    context 'FeatureSet overturned_trigger_fois enabled' do

      before(:each) do
        allow(FeatureSet).to receive(:overturned_trigger_fois).and_return(double 'Feature', enabled?: true)
      end

      permissions :request_further_clearance? do
        it { should     permit(manager,             unassigned_case) }
        it { should_not permit(other_manager,       unassigned_case) }
        it { should_not permit(responder,           unassigned_case) }
        it { should_not permit(press_officer,       unassigned_case) }
        it { should_not permit(private_officer,     unassigned_case) }
        it { should_not permit(disclosure_approver, unassigned_case) }
      end
    end

    context 'FeatureSet overturned_trigger_fois disabled' do

      before(:each) do
        allow(FeatureSet).to receive(:overturned_trigger_fois).and_return(double 'Feature', enabled?: false)
      end

      permissions :request_further_clearance? do
        it { should_not permit(manager,             unassigned_case) }
        it { should_not permit(other_manager,       unassigned_case) }
        it { should_not permit(responder,           unassigned_case) }
        it { should_not permit(press_officer,       unassigned_case) }
        it { should_not permit(private_officer,     unassigned_case) }
        it { should_not permit(disclosure_approver, unassigned_case) }
      end
    end
  end
end
