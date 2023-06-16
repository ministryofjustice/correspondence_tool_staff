require "rails_helper"

module ConfigurableStateMachine
  describe InvalidEventError do
    let(:kase)  { create :case }
    let(:user)  { create :user }

    context "no message provided" do
      it "prints the right message" do
        raise described_class.new(kase:,
                                  user:,
                                  event: "My dummy event",
                                  role: "approver")
      rescue StandardError => e
        expect(e).to be_instance_of(described_class)
        expect(e.message).to eq(<<~EOS)

          Invalid event: type: FOI
                         workflow: standard
                         role: approver
                         state: unassigned
                         event: My dummy event
                         kase_id: #{kase.id}
                         user_id: #{user.id}
        EOS
      end
    end

    context "message provided" do
      it "prints the right message" do
        raise described_class.new(kase:,
                                  user:,
                                  event: "My dummy event",
                                  role: "approver",
                                  message: "suddenly, error")
      rescue StandardError => e
        expect(e).to be_instance_of(described_class)
        expect(e.message).to eq(<<~EOS)

          Invalid event: type: FOI
                         workflow: standard
                         role: approver
                         state: unassigned
                         event: My dummy event
                         kase_id: #{kase.id}
                         user_id: #{user.id}
                         message: suddenly, error
        EOS
      end
    end
  end
end
