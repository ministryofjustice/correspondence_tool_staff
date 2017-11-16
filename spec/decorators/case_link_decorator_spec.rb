require 'rails_helper'

describe CaseLinkDecorator, type: :model do
  subject { CaseLinkDecorator.decorate create(:case) }

  it { should have_attributes linked_case_number: nil }
end
