require 'rails_helper'

RSpec.describe Correspondence, type: :model do

  let(:correspondence) { build :correspondence }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(correspondence).to be_valid
    end
  end

  describe 'attributes' do
    context 'mandatory' do
      it 'name' do
        correspondence.name = nil
        expect(correspondence).not_to be_valid
      end

      it 'email' do
        correspondence.email = nil
        expect(correspondence).not_to be_valid
      end

      it 'email confirmation' do
        correspondence.email_confirmation = nil
        expect(correspondence).not_to be_valid
        expect(correspondence.errors.full_messages).to include("Email confirmation can't be blank")
      end

      it 'category' do
        correspondence.category = nil
        expect(correspondence).not_to be_valid
      end

      it 'message' do
        correspondence.message = nil
        expect(correspondence).not_to be_valid
      end

      it 'topic' do
        correspondence.topic = nil
        expect(correspondence).not_to be_valid
      end
    end

    context 'requiring confirmation' do
      it 'email' do
        correspondence.email_confirmation = 'mis-match@email.com'
        expect(correspondence).not_to be_valid
        expect(correspondence.errors.full_messages).to include("Email confirmation doesn't match Email")
      end

      it 'email is case insensitive' do
        correspondence.email_confirmation = correspondence.email_confirmation.upcase
        expect(correspondence).to be_valid
      end
    end

    context 'with defaults' do
      it 'state - defaults to "submitted"' do
        expect(correspondence.state).to eq 'submitted'
      end
    end
  end

  context 'callbacks' do

    context '#assigned_state' do

      let(:persisted_correspondence) { create(:correspondence)  }
      let(:user)                     { create(:user)            }
      let(:another_user)             { create(:user)            }

      it 'is called after_update' do
        expect(persisted_correspondence).to receive(:assigned_state)
        persisted_correspondence.update(user_id: user.id)
      end

      context 'when user_id is updated' do
        it 'transitions state to "assigned"' do
          expect{ persisted_correspondence.update(user_id: user.id) }.to change{ persisted_correspondence.state }.from("submitted").to("assigned")
        end

        it 'unless state is already "assigned"' do
          persisted_correspondence.update(user_id: user.id)
          expect(persisted_correspondence).not_to receive(:assign)
          persisted_correspondence.update(user_id: another_user.id)
        end
      end
    end

  end

end
