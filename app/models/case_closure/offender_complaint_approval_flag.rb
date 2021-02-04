
module CaseClosure

  class OffenderComplaintApprovalFlag

    class ICOApprovalFlag < Metadatum
      def self.first_approval
        where(abbreviation: 'first_approval').singular
      end
  
      def self.second_approval
        where(abbreviation: 'second_approval').singular
      end
  
      def self.not_approval_required
        where(abbreviation: 'not_approval_required').singular
      end
  
      def first_approval?
        abbreviation == 'first_approval'
      end
  
      def second_approval?
        abbreviation == 'second_approval'
      end
  
      def not_approval_required?
        abbreviation == 'not_approval_required'
      end
    end
  
    class LitigationApprovalFlag < Metadatum
      def self.fee_approval
        where(abbreviation: 'fee_approval').singular
      end
  
      def fee_approval?
        abbreviation == 'fee_approval'
      end
    end

  end 
end
