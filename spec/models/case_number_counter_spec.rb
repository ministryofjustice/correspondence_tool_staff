# == Schema Information
#
# Table name: case_number_counters
#
#  id      :integer          not null, primary key
#  date    :date             not null
#  counter :integer          default(0)
#

require 'rails_helper'

RSpec.describe CaseNumberCounter, type: :model do
  let(:existing_counter) do
    CaseNumberCounter.find_or_create_by(
      date: Date.new(2017,1,1),
      counter: 1
    )
  end

  it 'does not allow us to create a duplicate record' do
    expect do
      CaseNumberCounter.create(date: existing_counter.date)
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe '.next_for_date' do
    it 'should increment an existing date' do
      expect do
        CaseNumberCounter.next_for_date(existing_counter.date)
      end.to change { existing_counter.reload.counter }.by 1
    end

    let(:new_date) { Date.new(2017, 1, 2) }

    it 'should create and increment a new date' do
      expect(CaseNumberCounter.find_by(date: new_date)).to be_nil
      CaseNumberCounter.next_for_date(new_date)
      expect(CaseNumberCounter.find_by(date: new_date).counter).to eq 1
    end
  end
end
