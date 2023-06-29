require "rails_helper"

RSpec.describe Case::ICO::FOIPolicy do
  let(:manager) { create :manager }

  describe Case::ICO::FOIPolicy::Scope do
    let(:foi_standard_scope) { instance_spy(Case::FOI::StandardPolicy::Scope) }

    before do
      allow(Case::FOI::StandardPolicy::Scope)
        .to receive(:new)
              .and_return(foi_standard_scope)
    end

    it "instantiates Case::FOI::StandardPolicy::Scope" do
      described_class.new(manager, Case::ICO::FOI.all).resolve

      expect(Case::FOI::StandardPolicy::Scope)
        .to have_received(:new).with(manager, Case::ICO::FOI.all, nil)
    end

    it "defers to resolving with Case::FOI::StandardPolicy::Scope" do
      result = described_class.new(manager, Case::ICO::FOI.all).resolve

      expect(foi_standard_scope).to have_received(:resolve)
      expect(result).to eq foi_standard_scope.resolve
    end
  end

  permissions :show? do
    it "defers to Case::FOI::StandardPolicy" do
      expect_any_instance_of(Case::FOI::StandardPolicy).to receive(:show?) # rubocop:disable RSpec/AnyInstance
      Pundit.policy(manager, Case::ICO::FOI).show?
    end
  end
end
