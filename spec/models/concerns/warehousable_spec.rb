require "rails_helper"

class DummyUserClass < ApplicationRecord
  include Warehousable

  self.table_name = "users"
end

class DummyRestrictedUserClass < DummyUserClass
  warehousable_attributes :full_name
end

class DummyMultipleRestrictedUserClass < DummyUserClass
  warehousable_attributes :full_name, :email
end

RSpec.describe Warehousable do
  context "when class doesn't restrict warehousable attributes" do
    let(:object) { DummyUserClass.create(full_name: "Dummy Class") }

    before { object.reload }

    it "creates a job when the object is saved" do
      expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("DummyUserClass", object.id)
      object.full_name = "Updated name"
      object.save!
    end
  end

  context "when class does restrict warehousable attributes" do
    let(:object) { DummyRestrictedUserClass.create(full_name: "Dummy Class") }

    before { object.reload }

    it "creates a job when the object is saved with a warehousable attribute" do
      expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("DummyRestrictedUserClass", object.id)
      object.full_name = "Updated name"
      object.save!
    end

    it "doesn't create a job when the object is saved with a non-warehousable attribute" do
      expect(::Warehouse::CaseSyncJob).not_to receive(:perform_later)
      object.email = "dummy@user.com"
      object.save!
    end
  end

  context "when class restricts multiple warehousable attributes" do
    let(:object) { DummyMultipleRestrictedUserClass.create(full_name: "Dummy Class", email: "email@email.com") }

    before { object.reload }

    it "creates a job when the object is saved with a warehousable attribute" do
      expect(::Warehouse::CaseSyncJob).to receive(:perform_later).with("DummyMultipleRestrictedUserClass", object.id)
      object.full_name = "Updated name"
      object.save!
    end

    it "doesn't create a job when the object is saved with a non-warehousable attribute" do
      expect(::Warehouse::CaseSyncJob).not_to receive(:perform_later)
      object.sign_in_count = 3
      object.save!
    end
  end
end
