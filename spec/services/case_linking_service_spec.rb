require "rails_helper"

describe CaseLinkingService do
  let(:manager)  { find_or_create :disclosure_bmt_user }
  let(:kase)     { create :case }
  let(:link_case) { create :case }
  let(:service) do
    described_class.new(manager,
                        kase,
                        link_case.number)
  end

  describe "#initialize" do
    it "uses the provided user" do
      urs = described_class.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@user)).to eq manager
    end

    it "uses the provided kase" do
      urs = described_class.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@case)).to eq kase
    end

    it "uses the provided link_case_number" do
      urs = described_class.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@link_case_number))
          .to eq link_case.number
    end

    it "initialises a empty link_case instance var" do
      urs = described_class.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@link_case)).to eq nil
    end

    it "user result and defaults to incomplete" do
      urs = described_class.new(manager, kase, link_case.number)
      expect(urs.instance_variable_get(:@result)).to eq :incomplete
    end
  end

  describe "#create" do
    context "as a manager" do
      context "NON-SAR cases" do
        it "creates a link to the linked case" do
          service.create!
          expect(kase.linked_cases).to eq [link_case]
        end

        it "creates a link from the linked case to the linking case" do
          service.create!
          expect(link_case.linked_cases).to eq [kase]
        end

        it "sets result to :ok and returns same" do
          result = service.create!
          expect(result).to eq :ok
          expect(service.result).to eq :ok
        end

        it "has created a transition on the linking case" do
          service.create!
          transition = kase.transitions.last
          expect(transition.event).to eq "link_a_case"
          expect(transition.to_state).to eq kase.current_state
          expect(transition.linked_case_id).to eq link_case.id
          expect(transition.acting_user_id).to eq manager.id
          expect(transition.acting_team_id).to eq manager.teams.first.id
        end

        it "has created a transition on the linked case" do
          service.create!
          transition = link_case.transitions.last
          expect(transition.event).to eq "link_a_case"
          expect(transition.to_state).to eq link_case.current_state
          expect(transition.linked_case_id).to eq kase.id
          expect(transition.acting_user_id).to eq manager.id
          expect(transition.acting_team_id).to eq manager.teams.first.id
        end
      end

      context "SAR cases" do
        let(:bmt)             { find_or_create :team_disclosure_bmt }
        let(:manager)         { bmt.users.first }
        let(:foi_case)        { create :case }
        let(:sar_case_1)      { create :sar_case, managing_team: bmt }
        let(:sar_case_2)      { create :sar_case }

        describe "linking a sar case to a  non sar case" do
          it "errors" do
            service = described_class.new(manager, sar_case_1, foi_case.number)
            service.create!
            expect(service.result).to eq :validation_error
            expect(sar_case_1.errors[:linked_case_number])
              .to eq ["cannot link a Non-offender SAR case to a FOI as a related case"]
          end
        end

        describe "linking a non-sar case to a sar case" do
          it "errors" do
            service = described_class.new(manager, foi_case, sar_case_1.number)
            service.create!
            expect(service.result).to eq :validation_error
            expect(foi_case.errors[:linked_case_number])
              .to eq ["cannot link a FOI case to a Non-offender SAR as a related case"]
          end
        end

        describe "linking a sar case to a sar case" do
          it "does not error" do
            service = described_class.new(manager, sar_case_1, sar_case_2.number)
            service.create!
            expect(service.result).to eq :ok
            expect(sar_case_1).to be_valid
          end
        end
      end
    end

    context "as a responder" do
      let(:responder) { kase.responder }

      context "NON-SAR cases" do
        it "creates a link to the linked case" do
          service.create!
          expect(kase.linked_cases).to eq [link_case]
        end

        it "creates a link from the linked case to the linking case" do
          service.create!
          expect(link_case.linked_cases).to eq [kase]
        end

        it "sets result to :ok and returns same" do
          result = service.create!
          expect(result).to eq :ok
          expect(service.result).to eq :ok
        end

        it "has created a transition on the linking case" do
          service.create!
          transition = kase.transitions.last
          expect(transition.event).to eq "link_a_case"
          expect(transition.to_state).to eq kase.current_state
          expect(transition.linked_case_id).to eq link_case.id
          expect(transition.acting_user_id).to eq manager.id
          expect(transition.acting_team_id).to eq manager.teams.first.id
        end

        it "has created a transition on the linked case" do
          service.create!
          transition = link_case.transitions.last
          expect(transition.event).to eq "link_a_case"
          expect(transition.to_state).to eq link_case.current_state
          expect(transition.linked_case_id).to eq kase.id
          expect(transition.acting_user_id).to eq manager.id
          expect(transition.acting_team_id).to eq manager.teams.first.id
        end
      end

      context "SAR cases" do
        let(:responder)       { find_or_create :foi_responder }
        let(:sar_case_1)      { create :accepted_sar, responder: }
        let(:sar_case_2)      { create :sar_case }

        describe "linking a sar case to a sar case" do
          it "errors if user is not a manager" do
            expect {
              service = described_class.new(responder, sar_case_1, sar_case_2.number)
              service.create!
            }.to raise_error CaseLinkingService::CaseLinkingError, "User requires manager role for linking SAR cases"
          end
        end
      end
    end
  end

  describe "#destroy" do
    context "NON-SAR cases" do
      before do
        service.create
      end

      it "destroys the link between the two cases" do
        service.destroy!
        expect(kase.linked_cases).to be_empty
        expect(link_case.linked_cases).to be_empty
      end

      it "sets result to :ok and returns same" do
        result = service.destroy
        expect(result).to eq :ok
        expect(service.result).to eq :ok
      end

      it "has created a transition on the linking case" do
        service.destroy!
        transition = kase.transitions.last
        expect(transition.event).to eq "remove_linked_case"
        expect(transition.to_state).to eq kase.current_state
        expect(transition.linked_case_id).to eq link_case.id
        expect(transition.acting_user_id).to eq manager.id
        expect(transition.acting_team_id).to eq manager.teams.first.id
      end

      it "has created a transition on the linked case" do
        service.destroy!
        transition = link_case.transitions.last
        expect(transition.event).to eq "remove_linked_case"
        expect(transition.to_state).to eq link_case.current_state
        expect(transition.linked_case_id).to eq kase.id
        expect(transition.acting_user_id).to eq manager.id
        expect(transition.acting_team_id).to eq manager.teams.first.id
      end
    end

    context "SAR cases" do
      let(:sar_case_1)      { create :sar_case }
      let(:sar_case_2)      { create :sar_case }
      let(:service)         do
        described_class.new(manager,
                            sar_case_1,
                            sar_case_2.number)
      end

      before do
        service.create
      end

      describe "linking a non-sar case to a sar case" do
        it "does not error" do
          service.destroy!
          expect(service.result).to eq :ok
          expect(sar_case_1).to be_valid
        end
      end
    end
  end

  context "validations" do
    describe "trying to link without a case number" do
      let(:service)  do
        described_class.new(manager,
                            kase,
                            nil)
      end

      it "sets result to validation error and returns same" do
        result = service.create!
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it "adds an error to the case" do
        service.create!
        expect(kase.errors[:linked_case_number])
          .to eq ["can't be blank"]
      end
    end

    describe "trying to link to the same case" do
      let(:service) do
        described_class.new(manager,
                            kase,
                            kase.number)
      end

      it "sets result to :validation error and returns same" do
        result = service.create!
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it "adds an error to the case" do
        service.create!
        expect(kase.errors[:linked_case_number])
          .to eq ["cannot link to the same case"]
      end
    end

    describe "trying to link a case that does not exist" do
      let(:service) do
        described_class.new(manager,
                            kase,
                            11_111)
      end

      it "sets result to validation error and returns same" do
        result = service.create!
        expect(result).to eq :validation_error
        expect(service.result).to eq :validation_error
      end

      it "adds an error to the case" do
        service.create!
        expect(kase.errors[:linked_case_number])
          .to eq ["does not exist"]
      end
    end
  end

  context "when an error occurs" do
    it "rolls back changes" do
      allow(kase.related_case_links)
        .to receive(:<<).and_raise(ActiveRecord::RecordInvalid)
      service.create!

      cases_transitions = kase.transitions.where(
        event: "link_a_case",
      )
      expect(cases_transitions.any?).to be false

      link_cases_transitions = link_case.transitions.where(
        event: "link_a_case",
      )
      expect(link_cases_transitions.any?).to be false
    end

    it "sets result to :error and returns same" do
      allow(kase.related_case_links)
        .to receive(:<<).and_raise(ActiveRecord::RecordInvalid)
      result = service.create!
      expect(result).to eq :error
      expect(service.result).to eq :error
    end
  end

  context "messy input" do
    let(:service) do
      described_class.new(manager,
                          kase,
                          "  #{link_case.number}  ")
    end

    it "strips whitespace out from the case number" do
      service.create!
      expect(service.result).to eq :ok
      expect(kase.linked_cases.first).to eq link_case
    end
  end
end
