require 'rails_helper'

RSpec.describe BaseFormObject do
  describe '#save' do
    before do
      allow(subject).to receive(:valid?).and_return(is_valid)
    end

    context 'for a valid form' do
      let(:is_valid) { true }

      it 'calls persist!' do
        expect(subject).to receive(:persist!)
        subject.save
      end
    end

    context 'for an invalid form' do
      let(:is_valid) { false }

      it 'does not call persist!' do
        expect(subject).not_to receive(:persist!)
        subject.save
      end

      it 'returns false' do
        expect(subject.save).to eq(false)
      end
    end
  end

  describe '#persisted?' do
    it 'always returns false' do
      expect(subject.persisted?).to eq(false)
    end
  end

  describe '#new_record?' do
    it 'always returns true' do
      expect(subject.new_record?).to eq(true)
    end
  end

  describe '#to_key' do
    it 'always returns nil' do
      expect(subject.to_key).to be_nil
    end
  end

  describe '[]' do
    let(:record) { double('Record') }

    before do
      subject.record = record
    end

    it 'read the attribute directly without using the method' do
      expect(subject).not_to receive(:record)
      expect(subject[:record]).to eq(record)
    end
  end

  describe '[]=' do
    let(:record) { double('Record') }

    it 'assigns the attribute directly without using the method' do
      expect(subject).not_to receive(:record=)
      subject[:record] = record
      expect(subject.record).to eq(record)
    end
  end
end
