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
module CaseClosure
  module ApprovalFlag
    class LitigationOffenderComplaint < CaseClosure::Metadatum
      def self.fee_approval
        where(abbreviation: "fee_approval").singular
      end

      def fee_approval?
        abbreviation == "fee_approval"
      end
    end
  end
end
