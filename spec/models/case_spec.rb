require 'rails_helper'

RSpec.describe Case, type: :model do

  let(:non_trigger_foi) { build :case, received_date: Date.parse('16/11/2016') }

  let(:trigger_foi) do
    build :case,
      received_date: Date.parse('16/11/2016'),
      properties: { trigger: true }
  end

  let(:general_enquiry) do
    build :case,
      received_date: Date.parse('16/11/2016'),
      category: create(:category, :gq)
  end

  let(:no_postal)           { build :case, postal_address: nil             }
  let(:no_postal_or_email)  { build :case, postal_address: nil, email: nil }
  let(:no_email)            { build :case, email: nil                      }
  let(:drafter)             { instance_double(User, drafter?: true)        }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(non_trigger_foi).to be_valid
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)          }
    it { should validate_presence_of(:message)       }
    it { should validate_presence_of(:received_date) }
    it { should validate_presence_of(:subject)       }
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
      non_trigger_foi.email_confirmation = 'does_not_match'
      expect(non_trigger_foi).not_to be_valid
    end

    it 'is case insensitive' do
      non_trigger_foi.email_confirmation = non_trigger_foi.email_confirmation.upcase
      expect(non_trigger_foi).to be_valid
    end
  end

  describe '#state' do
    it 'defaults to "submitted"' do
      expect(non_trigger_foi.state).to eq 'submitted'
    end
  end

  describe '#subject' do
    it { should validate_length_of(:subject).is_at_most(80) }
  end

  describe '#drafter' do
    it 'is the currently assigned drafter' do
      allow(non_trigger_foi).to receive(:assignees).and_return [drafter]
      expect(non_trigger_foi.drafter).to eq drafter
    end
  end

  describe 'associations' do
    describe '#category' do
      it 'is mandatory' do
        should validate_presence_of(:category)
      end

      it { should belong_to(:category) }
      it { should have_many(:assignments) }

    end
  end

  describe 'callbacks' do
    describe '#set_deadlines' do
      it 'is called before_create' do
        expect(non_trigger_foi).to receive(:set_deadlines)
        non_trigger_foi.save!
      end

      it 'is called after_update' do
        expect(non_trigger_foi).to receive(:set_deadlines)
        non_trigger_foi.update(category: Category.first)
      end

      it 'sets the escalation deadline for non_trigger_foi' do
        expect(non_trigger_foi.escalation_deadline).to eq nil
        non_trigger_foi.save!
        expect(non_trigger_foi.escalation_deadline.strftime("%d/%m/%y")).to eq "24/11/16"
      end

      it 'does not set the escalation deadline for trigger_foi' do
        expect(trigger_foi.escalation_deadline).to eq nil
        trigger_foi.save!
        expect(trigger_foi.escalation_deadline).to eq nil
      end

      it 'does not set the escalation deadline for general_enquiry' do
        expect(general_enquiry.escalation_deadline).to eq nil
        general_enquiry.save!
        expect(general_enquiry.escalation_deadline).to eq nil
      end

      it 'sets the internal deadline for trigger_foi' do
        expect(trigger_foi.internal_deadline).to eq nil
        trigger_foi.save!
        expect(trigger_foi.internal_deadline.strftime("%d/%m/%y")).to eq "30/11/16"
      end

      it 'sets the internal deadline for general enquiries' do
        expect(general_enquiry.internal_deadline).to eq nil
        general_enquiry.save!
        expect(general_enquiry.internal_deadline.strftime("%d/%m/%y")).to eq "30/11/16"
      end

      it 'does not set the internal_deadline for non_trigger_foi' do
        expect(non_trigger_foi.internal_deadline).to eq nil
        non_trigger_foi.save!
        expect(non_trigger_foi.internal_deadline).to eq nil
      end

      it 'sets the external deadline for all cases' do
        [non_trigger_foi, trigger_foi, general_enquiry].each do |kase|
          expect(kase.external_deadline).to eq nil
          kase.save!
          expect(kase.external_deadline.strftime("%d/%m/%y")).not_to eq nil
        end
      end
    end
  end
end
