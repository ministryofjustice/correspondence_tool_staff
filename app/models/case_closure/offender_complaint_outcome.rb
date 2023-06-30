# == Schema Information
#
module CaseClosure
  class OffenderComplaintOutcome < Metadatum
    def self.succeeded
      where(abbreviation: "succeeded").singular
    end

    def self.not_succeeded
      where(abbreviation: "not_succeeded").singular
    end

    def self.settled
      where(abbreviation: "settled").singular
    end

    def succeeded?
      abbreviation == "succeeded"
    end

    def not_succeeded?
      abbreviation == "not_succeeded"
    end

    def settled?
      abbreviation == "settled"
    end
  end
end
