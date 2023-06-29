# == Schema Information
#
# Table name: case_number_counters
#
#  id      :integer          not null, primary key
#  date    :date             not null
#  counter :integer          default(0)
#

require "rails_helper"

RSpec.describe CaseNumberCounter, type: :model do
  let(:existing_counter) do
    described_class.find_or_create_by(
      date: Date.new(2017, 1, 1),
      counter: 1,
    )
  end

  it "does not allow us to create a duplicate record" do
    expect {
      described_class.create(date: existing_counter.date)
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".next_for_date" do
    let(:new_date) { Date.new(2017, 1, 2) }

    it "increments an existing date" do
      expect {
        described_class.next_for_date(existing_counter.date)
      }.to change { existing_counter.reload.counter }.by 1
    end

    it "creates and increment a new date" do
      expect(described_class.find_by(date: new_date)).to be_nil
      described_class.next_for_date(new_date)
      expect(described_class.find_by(date: new_date).counter).to eq 1
    end
  end
end
