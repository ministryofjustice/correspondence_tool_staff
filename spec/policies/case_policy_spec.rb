require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:assigner)  { create(:user, roles: ['assigner'])}
  let(:drafter)   { create(:user, roles: ['drafter'])}

  permissions :can_add_case? do
    it "refuses unless current_user is an assigner" do
      expect(subject).not_to permit(drafter, Case.new)
    end

    it "grants if current_user is an assigner" do
      expect(subject).to permit(assigner, Case.new)
    end
  end
end
