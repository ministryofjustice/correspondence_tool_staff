require "rails_helper"

class DummyUserClass < ApplicationRecord
  include Warehousable

  self.table_name = "users"
end

class DummyRestrictedUserClass < ApplicationRecord
  include Warehousable

  self.table_name = "users"
  warehousable_attributes "full_name"
end

RSpec.describe Warehousable do
  context "when class doesn't restrict warehousable attributes" do
    let(:object) { DummyUserClass.create(full_name: "Dummy Class") }

    it "creates a job when the object is saved" do
      object.reload
      expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("DummyUserClass", object.id)
      object.full_name = "Updated name"
      object.save!
    end
  end

  context "when class does restrict warehousable attributes" do
    let(:object) { DummyRestrictedUserClass.create(full_name: "Dummy Class") }

    it "creates a job when the object is saved" do
      object.reload
      expect(::Warehouse::CaseSyncJob).not_to receive(:perform_later)
      object.email = "dummy@user.com"
      object.save!
    end
  end
end
