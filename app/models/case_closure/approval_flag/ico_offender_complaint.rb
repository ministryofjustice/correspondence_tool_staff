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
    class ICOOffenderComplaint < CaseClosure::Metadatum
      def self.first_approval
        where(abbreviation: "first_approval").singular
      end

      def self.second_approval
        where(abbreviation: "second_approval").singular
      end

      def self.no_approval_required
        where(abbreviation: "no_approval_required").singular
      end

      def first_approval?
        abbreviation == "first_approval"
      end

      def second_approval?
        abbreviation == "second_approval"
      end

      def no_approval_required?
        abbreviation == "no_approval_required"
      end
    end
  end
end
