require "rails_helper"

RSpec.describe ContactsController, type: :controller do
  let(:contacts) { ["stafford", "winson green", "brinsford"] }

  describe "#index" do
    it "returns an alphabetically sorted list of contacts" do
      # Assuming the controller action assigns @contacts
      get :index

      # Extract the contacts from the controller's instance variable
      contacts = assigns(:contacts)

      # Check if the contacts are sorted alphabetically
      expect(contacts).to eq(["brinsford", "stafford", "winson green"])
    end
  end
end
