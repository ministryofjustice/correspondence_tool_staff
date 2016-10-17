require 'rails_helper'

RSpec.describe Correspondence, type: :model do

  let(:correspondence)      { build :correspondence }
  let(:no_postal)           { build :correspondence, postal_address: nil }
  let(:no_postal_or_email)  { build :correspondence, postal_address: nil, email: nil }
  let(:no_email)            { build :correspondence, email: nil }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(correspondence).to be_valid
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)               }
    it { should validate_presence_of(:message)            }
    it { should validate_presence_of(:received_date)      }
  end

  context 'without a postal or email address' do
    it 'is invalid' do
      expect(no_postal_or_email).not_to be_valid
    end
  end

  context 'without a postal_address' do
    it 'is valid with an email address' do
      expect(no_postal).to be_valid
    end
  end

  context 'without an email address' do
    it 'is valid with a postal address' do
      expect(no_email).to be_valid
    end
  end

  describe '#email' do
    it { should allow_value('foo@bar.com').for :email     }
    it { should_not allow_value('foobar.com').for :email  }
  end

  describe '#email_confirmation' do
    it 'must match #email' do
      correspondence.email_confirmation = 'does_not_match'
      expect(correspondence).not_to be_valid
    end

    it 'is case insensitive' do
      correspondence.email_confirmation = correspondence.email_confirmation.upcase
      expect(correspondence).to be_valid
    end
  end

  describe '#state' do
    it 'defaults to "submitted"' do
      expect(correspondence.state).to eq 'submitted'
    end
  end

  describe 'associations' do

    describe '#category' do
      it 'is mandatory' do
        should validate_presence_of(:category)
      end

      it { should belong_to(:category) }

    end
  end

  describe 'callbacks' do
    describe '#set_deadlines' do
      it 'is called before_create' do
        expect(correspondence).to receive(:set_deadlines)
        correspondence.save!
      end

      it 'sets the internal deadline' do
        expect(correspondence.internal_deadline).to eq nil
        correspondence.save!
        expect(correspondence.internal_deadline).to be_a(Date)
      end

      it 'sets the external deadline' do
        expect(correspondence.external_deadline).to eq nil
        correspondence.save!
        expect(correspondence.external_deadline).to be_a(Date)
      end
    end

    describe '#assigned_state' do

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
end
