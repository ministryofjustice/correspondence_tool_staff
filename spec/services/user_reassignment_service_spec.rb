require "rails_helper"

describe UserReassignmentService do
  let(:accepted_case)    { create(:accepted_case, responder:) }
  let(:responder)        { find_or_create :foi_responder }
  let(:coworker)         do
    create :responder,
           responding_teams: [responding_team]
  end
  let(:responding_team) { responder.responding_teams.first }
  let(:assignment) do
    accepted_case
                             .assignments
                             .for_team(responding_team.id)
                             .last
  end

  describe "#initialize" do
    it "uses the provided target_team by default" do
      urs = described_class.new(target_user: coworker,
                                acting_user: responder,
                                assignment:,
                                target_team: :a_target_team)
      expect(urs.instance_variable_get(:@target_team)).to eq :a_target_team
    end

    it "uses the provided acting_team by default" do
      urs = described_class.new(target_user: coworker,
                                acting_user: responder,
                                assignment:,
                                acting_team: :an_acting_team)
      expect(urs.instance_variable_get(:@acting_team)).to eq :an_acting_team
    end

    context "when no target_team or acting_team provided" do
      let(:urs) do
        described_class.new(target_user: coworker,
                            acting_user: responder,
                            assignment:)
      end

      it "sets the target_team if not provided" do
        expect(urs.instance_variable_get(:@target_team)).to eq responding_team
      end

      it "sets the acting_team if not provided" do
        expect(urs.instance_variable_get(:@target_team)).to eq responding_team
      end
    end
  end

  describe "#call" do
    let(:service) do
      described_class.new(target_user: coworker,
                          acting_user: responder,
                          assignment:)
    end

    let(:policy) { service.instance_variable_get(:@policy) }

    context "when reassign the assignment" do
      it "returns :ok" do
        expect(service.call).to eq :ok
      end

      it "creates a transition record" do
        expect {
          service.call
        }.to change { accepted_case.transitions.count }.by(1)
      end

      it "updates the assignment record" do
        assignment = accepted_case.assignments
        service.call
        expect(accepted_case.assignments).to eq assignment
      end

      context "and an error occurs" do
        it "rolls-back changes" do
          old_user_id = assignment.user_id
          allow(assignment).to receive(:update).and_throw(RuntimeError)
          service.call

          # does not change the original assigned user
          expect(assignment.user_id).to eq old_user_id

          # no case history
          reassigned_user_transitions = accepted_case
                                              .transitions
                                              .where(event: "reassign_user")
          expect(reassigned_user_transitions.any?).to be false
        end

        it "sets result to :error and returns same" do
          allow(assignment).to receive(:update).and_throw(RuntimeError)
          result = service.call
          expect(result).to eq :error
          expect(service.result).to eq :error
        end
      end
    end

    context "when user assigns a case to themselves" do
      let(:service) do
        described_class.new(target_user: responder,
                            acting_user: responder,
                            assignment:)
      end

      it "does not send email" do
        service.call
        expect(service.result).to eq :no_changes
      end
    end

    context "when unassigned case" do
      let(:approver)         { find_or_create(:disclosure_specialist) }
      let(:unassigned_case)  { create(:foi_case, :flagged_accepted, approver:) }
      let(:approver_coworker) { create(:approver, approving_team: disclosure_team) }
      let(:disclosure_team)  { approver.approving_team }
      let(:assignment)       do
        unassigned_case
                                 .assignments
                                 .for_team(disclosure_team.id)
                                 .last
      end

      let(:service) do
        described_class.new(target_user: approver_coworker,
                            acting_user: approver,
                            assignment:)
      end

      let(:policy)          { service.instance_variable_get(:@policy) }

      context "and reassign the assignment" do
        it "returns :ok" do
          expect(service.call).to eq :ok
        end

        it "creates a transition record" do
          expect {
            service.call
          }.to change { unassigned_case.transitions.count }.by(1)
        end

        it "updates the assignment record" do
          assignment = unassigned_case.assignments
          service.call
          expect(unassigned_case.assignments).to eq assignment
        end
      end
    end
  end
end
