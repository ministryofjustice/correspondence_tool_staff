require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:another_responder) { create :responder}
  let(:managing_team)     { create :managing_team }
  let(:manager)           { managing_team.managers.first }

  let(:new_case) { create :case }
  let(:accepted_case) do
    create :accepted_case, responder: responder, manager: manager
  end
  let(:assigned_case) do
    create :assigned_case,
           responding_team: responding_team,
           manager: manager
  end
  let(:unassigned_case)    { new_case }
  let(:case_with_response) { create(:case_with_response, responder: responder) }
  let(:responded_case)     { create(:responded_case, responder: responder) }
  let(:closed_case)        { create(:closed_case, responder: responder) }

  permissions :can_accept_or_reject_case? do
    it "refuses if current_user is a manager" do
      expect(subject).not_to permit(manager, assigned_case)
    end

    it "grants if current_user is on the assigned responding team" do
      expect(subject).to permit(responder, assigned_case)
    end

    it "refuses if current_user is another responder" do
      expect(subject).not_to permit(another_responder, assigned_case)
    end
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it 'refuses if current_user is not the assigned responder' do
        expect(subject).not_to permit(another_responder, accepted_case)
      end

      it 'grants if current_user is the assigned responder' do
        expect(subject).to permit(responder, accepted_case)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(manager, accepted_case)
      end
    end

    context 'in awaiting_dispatch state' do
      it 'refuses if current_user is not the assigned responder' do
        expect(subject).not_to permit(another_responder, case_with_response)
      end

      it 'grants if current_user is the assigned responder' do
        expect(subject).to permit(responder, case_with_response)
      end

      it 'refuses if current_user is an assigner' do
        expect(subject).not_to permit(manager, case_with_response)
      end
    end
  end

  permissions :can_add_case? do
    it "refuses unless current_user is a manager" do
      expect(subject).not_to permit(responder, Case.new)
    end

    it "grants if current_user is a manager" do
      expect(subject).to permit(manager, Case.new)
    end
  end

  permissions :can_assign_case? do
    it "refuses unless current_user is a manager" do
      expect(subject).not_to permit(responder, new_case)
    end

    it "grants if current_user is a manager" do
      expect(subject).to permit(manager, new_case)
    end

    it "refuses if case is not in unassigned state" do
      expect(subject).not_to permit(manager, create(:assigned_case))
      expect(subject).not_to permit(responder, create(:assigned_case))
    end
  end

  permissions :can_close_case? do
    it "refuses unless current_user is a manager" do
      expect(subject).not_to permit(responder, create(:responded_case))
    end

    it "grants if current_user is a manager" do
      expect(subject).to permit(manager, create(:responded_case))
    end
  end

  permissions :can_respond? do
    it "refuses if current_user is a manager" do
      expect(subject).not_to permit(manager, case_with_response)
    end

    it "grants if current_user is the assigned responder" do
      expect(subject).to permit(responder, case_with_response)
    end

    it "refuses if current_user is another responder" do
      expect(subject).not_to permit(another_responder, case_with_response)
    end

    it 'refuses if case is not in awaiting dispatch' do
      kase = create :accepted_case
      expect(kase.current_state).to eq 'drafting'
      expect(subject).not_to permit(responder, kase)
    end
  end

  permissions :can_view_case_details? do
    it "refuses if current user is not involve in the case" do
      expect(subject).not_to permit(responder, new_case)

      expect(subject).not_to permit(another_responder, new_case)
      expect(subject).not_to permit(another_responder,
                                    create(:assigned_case,
                                           responder: responder))
      expect(subject).not_to permit(another_responder,
                                    create(:accepted_case,
                                           responder: responder))
      expect(subject).not_to permit(another_responder,
                                    create(:case_with_response,
                                           responder: responder))
      expect(subject).not_to permit(another_responder,
                                    create(:responded_case,
                                           responder: responder))
    end

    it "grants if current_user is a manager" do
      expect(subject).to permit(manager, new_case)
      expect(subject).to permit(manager, create(:assigned_case))
      expect(subject).to permit(manager, create(:accepted_case))
      expect(subject).to permit(manager, create(:case_with_response))
      expect(subject).to permit(manager, create(:responded_case))
    end

    it "grants if current_user is the responder for the case" do
      expect(subject).to permit(responder,
                                create(:assigned_case,
                                       responding_team: responding_team))
      expect(subject).to permit(responder,
                                create(:accepted_case, responder: responder))
      expect(subject).to permit(responder,
                                create(:case_with_response, responder: responder))
    end

  end

  permissions :can_remove_attachment? do
    context 'case is still being drafted' do
      let(:case_with_response) do
        create :case_with_response, responder: responder, manager: manager
      end

      it 'grants if current_user is the assigned responder' do
        expect(subject).to permit(responder, case_with_response)
      end

      it 'refuses if current_user is another responder' do
        expect(subject).not_to permit(another_responder, case_with_response)
      end

      it 'refuses if current_user is a manager' do
        expect(subject).not_to permit(manager, case_with_response)
      end
    end

    context 'case has been marked as responded' do
      let(:responded_case) do
        create :responded_case, responder: responder, manager: manager
      end

      it 'refuses if current_user is a responder' do
        expect(subject).not_to permit(another_responder, responded_case)
      end

      it 'refuses if current_user is a manager' do
        expect(subject).not_to permit(manager, responded_case)
      end
    end
  end

  describe 'case scope policy' do
    let(:existing_cases) do
      [
        unassigned_case,
        assigned_case,
        accepted_case,
        case_with_response,
        responded_case,
        closed_case,
      ]
    end

    it 'for managers - returns all cases' do
      existing_cases
      manager_scope = described_class::Scope.new(manager, Case.all).resolve
      expect(manager_scope).to eq existing_cases
    end

    it 'for responders - returns only their cases' do
      existing_cases
      responder_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(responder_scope).to eq [assigned_case, accepted_case, case_with_response]
    end

  end
end
