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
