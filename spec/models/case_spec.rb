# == Schema Information
#
# Table name: cases
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  state          :string           default("submitted")
#  category_id    :integer
#  received_date  :date
#  postal_address :string
#  subject        :string
#  properties     :jsonb
#  reference      :integer
#

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

  describe '#reference' do
    it 'is composed of the received date and an incremented suffix' do
      case_one = create(:case, received_date: Date.parse('11/01/2017'))
      case_two = create(:case, received_date: Date.parse('11/01/2017'))
      case_three = create(:case, received_date: Date.parse('12/01/2017'))
      case_four = create(:case, received_date: Date.parse('12/01/2017'))

      expect(case_one.reference).to eq    170111001
      expect(case_two.reference).to eq    case_one.reference + 1
      expect(case_three.reference).to eq  170112001
      expect(case_four.reference).to eq   case_three.reference + 1
    end

    it 'cannot be modified by update' do
      non_trigger_foi.save
      expect { non_trigger_foi.update(reference: 1) }.
        to raise_error StandardError, 'Reference is immutable'
    end

    it 'cannot be modified by save' do
      non_trigger_foi.save
      non_trigger_foi.reference = 1
      expect { non_trigger_foi.save }.
        to raise_error StandardError, 'Reference is immutable'
    end

    it 'must be unique' do
      allow(trigger_foi).to receive(:set_reference).and_return(1)
      allow(non_trigger_foi).to receive(:set_reference).and_return(1)
      expect(trigger_foi.save).to eq true
      expect(non_trigger_foi.save).to eq false
    end
  end 

  describe '#email' do
    it { should allow_value('foo@bar.com').for :email     }
    it { should_not allow_value('foobar.com').for :email  }
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

    describe '#prevent_reference_change' do
      it 'is called before_save' do
        expect(non_trigger_foi).to receive(:prevent_reference_change)
        non_trigger_foi.save!
      end
    end

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

    describe '#set_case_number' do
      it 'is called before_create' do
        expect(non_trigger_foi).to receive(:set_reference)
        non_trigger_foi.save
      end

      it 'assigns a case reference number' do
        expect(non_trigger_foi.reference).to eq nil
        non_trigger_foi.save
        expect(non_trigger_foi.reference).not_to eq nil
      end
    end
  end
end
