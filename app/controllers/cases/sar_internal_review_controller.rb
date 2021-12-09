module Cases
  class SarInternalReviewController < CasesController
    include SARInternalReviewCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.sar_internal_review
      @correspondence_type_key = 'sar_internal_review'
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.current_step = params[:step]

      @s3_direct_post = S3Uploader.for(@case, 'requests')

      @back_link = back_link_url
    end

    def create
      authorize case_type, :can_add_case?
      @case = build_case_from_session(case_type)
      @case.creator = current_user #to-do Remove when we use the case create service
      @case.current_step = params[:current_step]

      @s3_direct_post = S3Uploader.for(@case, 'requests')

      if @case.steps_are_completed? 
        @case.assign_attributes(create_params)
        if @case.valid?
          create_case
        else
          render :new
        end
      else
        if @case.valid_attributes?(create_params)
          go_next_step
        else
          render :new
        end
      end
    end

    def case_type
      Case::SAR::InternalReview
    end

    def create_case
      @case.save
      session[session_state] = nil
      flash[:creating_case] = true
      flash[:notice] = "Case created successfully"
      make_case_a_triggered_case
      redirect_to new_case_assignment_path @case
    end

    def make_case_a_triggered_case
      CaseFlagForClearanceService.new(
        user: current_user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure
      ).call
    end

    def create_params
      create_sar_internal_review_params
    end

    def build_case_from_session(correspondence_type)
      # TODO: copied from OffenderSarController
      # Need to refactor to DRY out between two
      values = session[session_state] 

      correspondence_type.new(values).decorate
    end

    def go_next_step
      copy_params = create_params
      copy_params = @case.process_params_after_step(copy_params)
      session_persist_state(copy_params)
      get_next_step(@case)
      redirect_to "#{@case.case_route_path}/#{@case.current_step}"
    end

    def get_next_step(obj)
      obj.current_step = params[:current_step]

      if params[:previous_button]
        obj.previous_step
      elsif params[:commit]
        obj.next_step
      end
    end

    def session_persist_state(params)
      session[session_state] ||= {}
      params ||= {}
      session[session_state].merge! params
    end

    def session_state
      # TODO: Copied from OffenderSarController
      # Refactor
      "#{@correspondence_type_key}_state".to_sym
    end

    def back_link_url
      if @case.get_previous_step       
        "#{@case.case_route_path}/#{@case.get_previous_step}"
      else
        new_case_path
      end
    end

  end
end
