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
