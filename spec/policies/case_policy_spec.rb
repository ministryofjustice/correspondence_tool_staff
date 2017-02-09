require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:assigner)        { create(:assigner) }
  let(:drafter)         { create(:drafter)  }
  let(:another_drafter) { create(:drafter) }
  let(:approver)        { create(:approver) }

  permissions :can_add_attachment? do
    let(:accepted_case) do
      create :accepted_case, drafter: drafter, assigner: assigner
    end

    it 'refuses if current_user is not the assigned drafter' do
      expect(subject).not_to permit(another_drafter, accepted_case)
    end

    it 'grants if current_user is the assigned drafter' do
      expect(subject).to permit(drafter, accepted_case)
    end

    it 'grants if current_user is an assigner' do
      expect(subject).to permit(assigner, accepted_case)
    end

    it 'refuses if current_user is not the drafter or an assigner' do
      expect(subject).not_to permit(approver, accepted_case)
    end
  end

  permissions :can_add_case? do
    it "refuses unless current_user is an assigner" do
      expect(subject).not_to permit(drafter, Case.new)
    end

    it "grants if current_user is an assigner" do
      expect(subject).to permit(assigner, Case.new)
    end
  end

  permissions :can_assign_case? do
    it "refuses unless current_user is an assigner" do
      expect(subject).not_to permit(drafter, create(:case))
    end

    it "grants if current_user is an assigner" do
      expect(subject).to permit(assigner, create(:case))
    end

    it "refuses if case is not in unassigned state" do
      expect(subject).not_to permit(assigner, create(:assigned_case))
      expect(subject).not_to permit(drafter, create(:assigned_case))
    end
  end

  permissions :can_accept_or_reject_case? do
    let(:assigned_case) do
      create(:assigned_case, drafter: drafter, assigner: assigner)
    end

    it "refuses if current_user is an assigner" do
      expect(subject).not_to permit(assigner, assigned_case)
    end

    it "grants if current_user is the assigned drafter" do
      expect(subject).to permit(drafter, assigned_case)
    end

    it "refuses if current_user is another drafter" do
      expect(subject).not_to permit(another_drafter, assigned_case)
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

  describe 'case scope policy' do
    let(:unassigned_case) { create(:case)          }
    let(:assigned_case)   { create(:assigned_case) }
    let(:drafter)         { assigned_case.drafter  }
    let(:assigner)        { create(:assigner)      }

    it 'for assigners - returns all cases' do
      assigner_scope = described_class::Scope.new(assigner, Case.all).resolve
      expect(assigner_scope).to include(unassigned_case, assigned_case)
      expect(assigner_scope.count).to eq 2
    end

    it 'for drafters - returns only their cases' do
      drafter_scope = described_class::Scope.new(drafter, Case.all).resolve
      expect(drafter_scope).to eq [assigned_case]
    end
  end
end
