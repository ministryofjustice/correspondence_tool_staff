module Cases
  class CaseTransitionsController < CasesController
    def create
      @case = Case::Base.find(params[:case_id])
      # authorize @case

    end
  end
end
