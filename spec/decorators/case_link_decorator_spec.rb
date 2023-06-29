require "rails_helper"

describe CaseLinkDecorator, type: :model do
  subject { described_class.decorate create(:case) }

  it { is_expected.to have_attributes linked_case_number: nil }
end
