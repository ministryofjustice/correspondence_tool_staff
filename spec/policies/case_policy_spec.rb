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

  permissions :can_close_case? do
    it "refuses unless current_user is an assigner" do
      expect(subject).not_to permit(drafter, create(:responded_case))
    end

    it "grants if current_user is an assigner" do
      expect(subject).to permit(assigner, create(:responded_case))
    end
  end
end
