require 'rails_helper'

module ConfigurableStateMachine

  describe InvalidEventError do

    let(:kase)  { create :case }
    let(:user)  { create :user }

    it 'prints the right message' do
      begin
        raise InvalidEventError.new(kase: kase, user: user, event: 'My dummy event', role: 'approver')
      rescue => err
        expect(err).to be_instance_of(InvalidEventError)
        expect(err.message).to eq("\nInvalid event: type: FOI\n" +
                                  "               workflow: standard\n" +
                                  "               role: approver\n" +
                                  "               state: unassigned\n" +
                                  "               event: My dummy event\n" +
                                  "               kase_id: #{kase.id}\n" +
                                  "               user_id: #{user.id}")
      end
    end


  end
end
