module Cases
  class OffenderSarComplaintController < OffenderSarController
    include OffenderSARComplaintCasesParams

    def initialize
      super
      @correspondence_type = CorrespondenceType.offender_sar_complaint
      @correspondence_type_key = 'offender_sar_complaint'
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      @case = build_case_from_session(Case::SAR::OffenderComplaint)
      @case.current_step = params[:step]
    end

    def create
      authorize case_type, :can_add_case?

      @case = build_case_from_session(Case::SAR::OffenderComplaint)
      @case.creator = current_user #to-do Remove when we use the case create service
      @case.current_step = params[:current_step]

      if !@case.valid_attributes?(create_params)
        render :new
      elsif @case.valid? && @case.save
        session[session_state] = nil
        flash[:notice] = "Case created successfully"
        redirect_to case_path(@case)
      else
        session_persist_state(create_params)
        get_next_step(@case)
        redirect_to "#{step_case_sar_offender_complaint_index_path}/#{@case.current_step}"
      end
    end

    private

    def set_case_types
      @case_types = ["Case::SAR::OffenderComplaint"]
    end

    def case_type
      Case::SAR::OffenderComplaint
    end

    def create_params
      create_offender_sar_complaint_params
    end

    def edit_params
      create_offender_sar_complaint_params
    end

    def update_params
      create_offender_sar_complaint_params
    end

    def respond_offender_sar_params
      create_offender_sar_complaint_params
    end

    def session_state
      "#{@correspondence_type_key}_state".to_sym
    end
  end
end
