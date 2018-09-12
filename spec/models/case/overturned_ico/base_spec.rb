require 'rails_helper'

describe Case::OverturnedICO::Base do


  let(:original_case)     { create :sar_case,
                                   subject: 'My original SAR case',
                                   delivery_method: 'sent_by_post' }
  let(:ico_appeal)        { create :ico_sar_case, original_case: original_case, ico_officer_name: 'Dan Dare' }
  let(:overturned_ico)    { create :overturned_ico_sar,
                                   original_ico_appeal_id: ico_appeal.id,
                                   original_case_id: original_case.id }


  describe 'delivery method validations' do
    context 'send_by_email' do
      it 'is invalid if no email address specified' do
        overturned_ico.email = nil
        expect(overturned_ico).not_to be_valid
        expect(overturned_ico.errors[:email]).to eq ["can't be blank"]
      end
    end

    context 'send by post' do
      it 'is invalid if no postal address specified' do
        overturned_ico.reply_method = 'send_by_post'
        expect(overturned_ico).not_to be_valid
        expect(overturned_ico.errors[:postal_address]).to eq ["can't be blank"]
      end
    end
  end

  describe 'ico_reference_number' do
    it 'delegates to the origin ICO Appeal' do
      expect(overturned_ico).to delegate_method(:ico_reference_number)
                                  .to(:original_ico_appeal)
    end
  end

  describe 'ico_decision' do
    it 'delegates to the origin ICO Appeal' do
      expect(overturned_ico).to delegate_method(:ico_decision)
                                  .to(:original_ico_appeal)
    end
  end

  describe 'ico_decision_comment' do
    it 'delegates to the origin ICO Appeal' do
      expect(overturned_ico).to delegate_method(:ico_decision_comment)
                                  .to(:original_ico_appeal)
    end
  end

  describe 'date_ico_decision_received' do
    it 'delegates to the origin ICO Appeal' do
      expect(overturned_ico).to delegate_method(:date_ico_decision_received)
                                  .to(:original_ico_appeal)
    end
  end

  describe 'ico_decision_attachments' do
    it 'delegates to the origin ICO Appeal' do
      expect(overturned_ico).to delegate_method(:ico_decision_attachments)
                                  .to(:original_ico_appeal)
    end
  end

  describe '#subject' do
    it 'returns the subject from the original case' do
      expect(overturned_ico.subject).to eq 'My original SAR case'
    end
  end


  describe '#delivery_method' do
    context 'no delivery method set on this overturned record' do
      it 'gets the delivery method from the original case' do
        overturned_ico[:delivery_method] = nil
        expect(overturned_ico.delivery_method).to eq 'sent_by_post'
      end
    end

    context 'delivery method set on this overturned record' do
      it 'uses the delivery method on this record and not the original case' do
        overturned_ico[:delivery_method] = 'sent_by_email'
        expect(overturned_ico.delivery_method).to eq 'sent_by_email'
      end
    end
  end


  describe '#delivery_method=' do
    context 'using attribute assignement' do
      it 'sets the delivery method on this overturned record and leaves the original case untouched' do
        overturned_ico.delivery_method = 'sent_by_email'
        overturned_ico.save
        expect(overturned_ico[:delivery_method]).to eq 'sent_by_email'
        expect(original_case.delivery_method).to eq 'sent_by_post'
      end
    end

    context 'using update' do
      it 'sets the delivery method on this overturned record and leaves the original case untouched' do
        overturned_ico.update(delivery_method: 'sent_by_email')
        expect(overturned_ico[:delivery_method]).to eq 'sent_by_email'
        expect(original_case.delivery_method).to eq 'sent_by_post'
      end
    end
  end

  describe '#ico_officer_name' do
    it 'copies from original_ico_appeal' do
      expect(overturned_ico.ico_officer_name).to eq 'Dan Dare'
    end
  end

  describe '#ico_officer_name=' do
    before(:each)   { overturned_ico.ico_officer_name = 'Albert Fitzwilliam Digby' }

    it 'changes the name' do
      expect(overturned_ico.ico_officer_name).to eq 'Albert Fitzwilliam Digby'
    end

    it 'does not change the ico officer name on the original appeal' do
      expect(overturned_ico.original_ico_appeal.ico_officer_name).to eq 'Dan Dare'
    end

    it 'is not valid if not set' do
      overturned_ico.ico_officer_name = ''
      expect(overturned_ico).not_to be_valid
      expect(overturned_ico.errors[:ico_officer_name]).to include("can't be blank")
    end

  end


end
