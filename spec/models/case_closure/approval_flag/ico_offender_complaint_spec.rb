# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#  active                  :boolean          default(TRUE)
#  omit_for_part_refused   :boolean          default(FALSE)
#
require "rails_helper"

module CaseClosure
  module ApprovalFlag
    RSpec.describe ICOOffenderComplaint, type: :model do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:abbreviation) }
      it { is_expected.to validate_presence_of(:sequence_id) }

      describe ".id_from_name" do
        it "returns the id when name exists in the database" do
          complaint_first_approval = create :offender_ico_complaint_approval_flag, :first_approval
          complaint_second_approval = create :offender_ico_complaint_approval_flag, :second_approval
          complaint_no_approval_required = create :offender_ico_complaint_approval_flag, :no_approval_required

          expect(described_class.id_from_name(complaint_first_approval.name))
            .to eq complaint_first_approval.id
          expect(described_class.id_from_name(complaint_second_approval.name))
            .to eq complaint_second_approval.id
          expect(described_class.id_from_name(complaint_no_approval_required.name))
            .to eq complaint_no_approval_required.id

          expect(described_class.first_approval).to eq complaint_first_approval
          expect(described_class.second_approval).to eq complaint_second_approval
          expect(described_class.no_approval_required).to eq complaint_no_approval_required
        end

        it "returns nil when no record with specified name" do
          expect(described_class.id_from_name("xxxxxxxx")).to be nil
        end
      end
    end
  end
end
