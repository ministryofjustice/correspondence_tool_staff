module DataRequestCalculator
  class Mappa < Standard
    def deadline_days
      20
    end

  private

    def escalation_after
      1
    end
  end
end
