require "rails_helper"

RSpec.describe Case::ICO::SARPolicy do
  let(:manager) { create :manager }

  describe Case::ICO::SARPolicy::Scope do
    let(:sar_standard_scope) { instance_spy(Case::SARPolicy::Scope) }

    before do
      allow(Case::SARPolicy::Scope)
        .to receive(:new)
              .and_return(sar_standard_scope)
    end

    it "instantiates Case::SARPolicy::Scope" do
      described_class.new(manager, Case::ICO::SAR.all).resolve

      expect(Case::SARPolicy::Scope)
        .to have_received(:new).with(manager, Case::ICO::SAR.all, nil)
    end

    it "defers to resolving with Case::SARPolicy::Scope" do
      result = described_class.new(manager, Case::ICO::SAR.all).resolve

      expect(sar_standard_scope).to have_received(:resolve)
      expect(result).to eq sar_standard_scope.resolve
    end
  end

  permissions :show? do
    it "defers to Case::SARPolicy" do
      expect_any_instance_of(Case::SARPolicy).to receive(:show?)
      Pundit.policy(manager, Case::ICO::SAR).show?
    end
  end
end
