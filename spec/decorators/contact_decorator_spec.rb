require 'rails_helper'

describe ContactDecorator, type: :model do
  let(:contact_with_emails) { create(:contact, data_request_emails: 'test@test.com').decorate }
  let(:contact_without_emails) { create(:contact, data_request_emails: '').decorate }

  describe :has_emails? do
    it 'returns No if the contact has no emails' do
      expect(contact_without_emails.has_emails?).to eq 'No'
    end

    it 'returns Yes if the contact has emails' do
      expect(contact_with_emails.has_emails?).to eq 'Yes'
    end
  end
end
