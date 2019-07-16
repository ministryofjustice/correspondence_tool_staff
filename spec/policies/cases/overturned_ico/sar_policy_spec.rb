require 'rails_helper'

RSpec.describe Case::OverturnedICO::SARPolicy do
  subject { described_class }

  let(:managing_team)         { find_or_create :team_dacu }
  let(:other_managing_team)   { create :managing_team }
  let(:manager)               { managing_team.managers.first }
  let(:responding_team)       { create :responding_team }
  let(:responder)             { responding_team.responders.first }
  let(:dacu_disclosure)       { find_or_create :team_dacu_disclosure }
  let(:disclosure_specialist) { dacu_disclosure.approvers.first }

  let(:unassigned_case)       { create :overturned_ico_sar }

  let(:manager)               { managing_team.managers.first }
  let(:other_manager)         { other_managing_team.managers.first }
  let(:responder)             { responding_team.responders.first }
  let(:press_officer)         { find_or_create :press_officer }
  let(:private_officer)       { find_or_create :private_officer }
  let(:disclosure_approver)   { dacu_disclosure.approvers.first }


  permissions :can_add_case? do
    it { should     permit(manager,                 Case::OverturnedICO::SAR) }
    it { should_not permit(disclosure_specialist,   Case::OverturnedICO::SAR) }
    it { should_not permit(responder,               Case::OverturnedICO::SAR) }
  end

  permissions :new? do
    context 'feature set enabled' do
      it 'the feature set is enabled' do
        expect(FeatureSet.ico.enabled?).to be true
      end

      context 'manager' do
        it { should permit(manager, Case::OverturnedICO::Base) }
      end

      context 'responder' do
        it { should_not permit(responder, Case::OverturnedICO::Base) }
      end

      context 'approver' do
        it { should_not permit(disclosure_specialist, Case::OverturnedICO::Base) }
      end

      context 'feature set not enabled' do
        before(:each) do
          # override whatever is in the settings file with these settings
          @original_ico_settings = Settings.enabled_features.ico
          Settings.enabled_features.ico = Config::Options.new({
                                                                   :"Local" => false,
                                                                   :"Host-dev" => true,
                                                                   :"Host-demo" => true,
                                                                   :"Host-staging" => false,
                                                                   :"Host-production" => false
                                                               })
        end

        after(:each) {
          Settings.enabled_features.ico = @original_ico_settings
        }

        it 'disables the feature set' do
          expect(FeatureSet.ico.enabled?).to be false
        end

        context 'manager' do
          it { should_not permit(manager, Case::OverturnedICO::Base) }
        end

        context 'responder' do
          it { should_not permit(responder, Case::OverturnedICO::Base) }
        end

        context 'approver' do
          it { should_not permit(disclosure_specialist, Case::OverturnedICO::Base) }
        end
      end
    end
  end


  permissions :show? do
    context 'unassigned case' do
      it { should     permit(manager,               unassigned_case) }
      it { should_not permit(responder,             unassigned_case) }
      it { should_not permit(disclosure_specialist, unassigned_case) }
    end

    context 'linked case' do
      let!(:linked_case) do
        create(:closed_sar, responding_team: responding_team).tap do |kase|
          unassigned_case.related_cases << kase
        end
      end

      it { should_not permit(responder,             unassigned_case) }
      it { should_not permit(disclosure_specialist, unassigned_case) }
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
end
