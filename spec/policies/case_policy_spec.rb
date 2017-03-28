require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:assigner)        { create(:assigner) }
  let(:drafter)         { create(:drafter)  }
  let(:another_drafter) { create(:drafter) }
  let(:approver)        { create(:approver) }

  let(:accepted_case) do
    create :accepted_case, drafter: drafter, assigner: assigner
  end
  let(:assigned_case) do
    create(:assigned_case, drafter: drafter, assigner: assigner)
  end
  let(:case_with_response) do
    create(:case_with_response, drafter: drafter)
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it 'refuses if current_user is not the assigned drafter' do
        expect(subject).not_to permit(another_drafter, accepted_case)
      end

      it 'grants if current_user is the assigned drafter' do
        expect(subject).to permit(drafter, accepted_case)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(assigner, accepted_case)
      end

      it 'refuses if current_user is not the drafter or an assigner' do
        expect(subject).not_to permit(approver, accepted_case)
      end
    end

    context 'in awaiting_dispatch state' do
      it 'refuses if current_user is not the assigned drafter' do
        expect(subject).not_to permit(another_drafter, case_with_response)
      end

      it 'grants if current_user is the assigned drafter' do
        expect(subject).to permit(drafter, case_with_response)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(assigner, case_with_response)
      end

      it 'refuses if current_user is not the drafter or an assigner' do
        expect(subject).not_to permit(approver, case_with_response)
      end
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

  permissions :can_respond? do
    it "refuses if current_user is an assigner" do
      expect(subject).not_to permit(assigner, case_with_response)
    end

    it "grants if current_user is the assigned drafter" do
      expect(subject).to permit(drafter, case_with_response)
    end

    it "refuses if current_user is another drafter" do
      expect(subject).not_to permit(another_drafter, case_with_response)
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

  permissions :can_view_case_details? do
    it "refuses if current user is not involve in the case" do
      expect(subject).not_to permit(drafter, create(:case))

      expect(subject).not_to permit(another_drafter, create(:case))
      expect(subject).not_to permit(another_drafter, create(:assigned_case, drafter: drafter))
      expect(subject).not_to permit(another_drafter, create(:accepted_case, drafter: drafter))
      expect(subject).not_to permit(another_drafter, create(:case_with_response, drafter: drafter))
      expect(subject).not_to permit(another_drafter, create(:responded_case, drafter: drafter))
    end

    it "grants if current_user is an assigner" do
      expect(subject).to permit(assigner, create(:case))
      expect(subject).to permit(assigner, create(:assigned_case))
      expect(subject).to permit(assigner, create(:accepted_case))
      expect(subject).to permit(assigner, create(:case_with_response))
      expect(subject).to permit(assigner, create(:responded_case))
    end

    it "grants if current_user is the drafter for the case" do
      expect(subject).to permit(drafter, create(:assigned_case,drafter: drafter))
      expect(subject).to permit(drafter, create(:accepted_case,drafter: drafter))
      expect(subject).to permit(drafter, create(:case_with_response,drafter: drafter))
      expect(subject).to permit(drafter, create(:responded_case,drafter: drafter))
    end

  end

  permissions :can_remove_attachment? do
    context 'case is still being drafted' do
      let(:case_with_response) do
        create :case_with_response, drafter: drafter, assigner: assigner
      end

      it 'grants if current_user is the assigned drafter' do
        expect(subject).to permit(drafter, case_with_response)
      end

      it 'refuses if current_user is another drafter' do
        expect(subject).not_to permit(another_drafter, case_with_response)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(assigner, case_with_response)
      end

      it 'refuses if current_user is an approver' do
        expect(subject).not_to permit(approver, case_with_response)
      end
    end

    context 'case has been marked as responded' do
      let(:responded_case) do
        create :responded_case, drafter: drafter, assigner: assigner
      end

      it 'refuses if current_user is a drafter' do
        expect(subject).not_to permit(another_drafter, responded_case)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(assigner, responded_case)
      end

      it 'refuses if current_user is an approver' do
        expect(subject).not_to permit(approver, responded_case)
      end
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
