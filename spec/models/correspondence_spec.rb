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

      it do
        should validate_presence_of(:name)
        should validate_presence_of(:email)
        should validate_presence_of(:email_confirmation)
        should validate_presence_of(:message)
        should validate_presence_of(:topic)
      end
    end

    context 'requiring confirmation' do
      it { should validate_confirmation_of(:email) }

      it 'for email is case insensitive' do
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

  describe 'associations' do

    context 'category' do

      it 'is mandatory' do
        should validate_presence_of(:category)
      end

      it { should belong_to(:category) }

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
          persisted_correspondence.update(user_id: user.id)
          expect(described_class.first.state).to eq 'assigned'
        end

        it 'unless state is already "assigned"' do
          persisted_correspondence.update(user_id: user.id)
          expect(persisted_correspondence).not_to receive(:assign)
          persisted_correspondence.update(user_id: another_user.id)
        end
      end
    end
  end

  context '#internal_deadline' do

    context 'for General Enquiries' do

      before do
        Timecop.freeze('05/08/2016') { create(:correspondence, category: create(:category, name: 'general_enquiries')) }
      end

      it 'is 11 working days including the day of receipt' do
        expect(Correspondence.first.internal_deadline).to eq '19/08/2016'
      end
    end

    context 'Freedom of Information Requests' do

      before do
        Timecop.freeze('05/08/2016') { create(:correspondence, category: create(:category, name: 'freedom_of_information_request')) }
      end

      it 'is 11 working days including the day of receipt' do
        expect(Correspondence.first.internal_deadline).to eq '26/08/2016'
      end

    end

  end
end
