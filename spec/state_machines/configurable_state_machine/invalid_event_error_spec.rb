require 'rails_helper'

module ConfigurableStateMachine

  describe InvalidEventError do

    let(:kase)  { create :case }
    let(:user)  { create :user }

    it 'prints the right message' do
      begin
        raise InvalidEventError.new(kase: kase, user: user, event: 'My dummy event')
      rescue => err
        expect(err).to be_instance_of(InvalidEventError)
        expect(err.message).to eq "Invalid Event: 'My dummy event': case_id: #{kase.id}, user_id: #{user.id}"
      end
    end


  end
end
