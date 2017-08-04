require 'rails_helper'

describe TeamPolicy do


  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  subject { described_class }

  permissions :index? do
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end

  permissions :show? do
    it { should     permit(manager,     Team.first)  }
    it { should_not permit(responder,   Team.first) }
    it { should_not permit(approver,    Team.first) }
  end
end
