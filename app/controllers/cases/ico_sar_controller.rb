module Cases
  class ICOSARController < ICOController
    before_action -> { set_decorated_case(params[:id]) }, only: %i[record_complaint_outcome confirm_record_complaint_outcome]

    def new
      authorize case_type, :can_add_case?

      permitted_correspondence_types
      new_case_for @correspondence_type, case_type
    end

    def case_type
      Case::ICO::SAR
    end

    def record_complaint_outcome
      authorize @case, :can_set_outcome?
      render "cases/ico/sar/record_complaint_outcome"
    end

    def confirm_record_complaint_outcome
      authorize @case, :can_set_outcome?
      @case.prepare_for_recording_outcome
      if @case.update(record_complaint_outcome_params)
        @case.respond(current_user)
        redirect_to case_path(@case)
      else
        render "cases/ico/sar/record_complaint_outcome"
      end
    end
  end
end
