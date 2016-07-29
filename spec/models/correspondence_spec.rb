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

      it 'tpoic' do
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
  end
end
