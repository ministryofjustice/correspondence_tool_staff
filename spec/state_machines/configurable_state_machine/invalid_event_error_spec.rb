require 'rails_helper'

module ConfigurableStateMachine

  describe InvalidEventError do

    let(:kase)  { create :case }
    let(:user)  { create :user }

    context 'no message provided' do
      it 'prints the right message' do
        begin
          raise InvalidEventError.new(kase: kase,
                                      user: user,
                                      event: 'My dummy event',
                                      role: 'approver')
        rescue => err
          expect(err).to be_instance_of(InvalidEventError)
          expect(err.message).to eq(<<~EOS)

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
    end

    context 'message provided' do
      it 'prints the right message' do
        begin
          raise InvalidEventError.new(kase: kase,
                                      user: user,
                                      event: 'My dummy event',
                                      role: 'approver',
                                      message: 'suddenly, error')
        rescue => err
          expect(err).to be_instance_of(InvalidEventError)
          expect(err.message).to eq(<<~EOS)

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
end
