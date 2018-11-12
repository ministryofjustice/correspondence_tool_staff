require 'rails_helper'

describe UserPolicy do
  let(:responding_team) { create :responding_team }
  let(:manager)         { create :manager }
  let(:responder)       { find_or_create :foi_responder }
  let(:approver)        { create :approver }

  subject { described_class }

  permissions :destroy? do
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end
end
