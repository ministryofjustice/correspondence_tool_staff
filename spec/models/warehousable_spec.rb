require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#warehouse_closed_report' do
    let(:feedback) {
      fe = spy('Feedback')
      expect(fe).to have_received(:create!).exactly(:twice)
      fe = Feedback.create!(comment: 'Test', email: 'test@mail.com')
    }

    before(:each) do
      # feedback
      # model = spy('feedback')
      #
      # expect(model).to have_received(:warehouse_closed_report).exactly(:twice)
    end

    context 'on save' do
      it 'executes' do
        feedback
      end
    end

    context 'on update' do
      it 'executes' do
        model.update!(comment: 'Edited the comment')
      end
    end

    context 'on destroy' do
      it 'executes' do
        model.destroy!
      end
    end

    context 'on delete' do
      it 'executes' do
        model.delete
      end
    end
  end
end
