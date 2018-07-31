require 'rails_helper'

RSpec.describe Case::OverturnedICO::SARPolicy do
  subject { described_class }
  let(:manager)     { create :manager }
  let(:approver)    { create :disclosure_specialist }
  let(:responder)   { create :responder}


  permissions :can_add_case? do
    it { should     permit(manager,     Case::OverturnedICO::SAR) }
    it { should_not permit(approver,    Case::OverturnedICO::SAR) }
    it { should_not permit(responder,   Case::OverturnedICO::SAR) }
  end

  permissions :new_overturned_ico? do
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
        it { should_not permit(approver, Case::OverturnedICO::Base) }
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
          it { should_not permit(approver, Case::OverturnedICO::Base) }
        end
      end
    end
  end
end
