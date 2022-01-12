module Cases
  class SarInternalReviewController < CasesController
    include SARInternalReviewCasesParams

    def initialize
      super

      @correspondence_type = CorrespondenceType.sar_internal_review
      @correspondence_type_key = case_type.type_abbreviation.downcase
    end

    def new
      permitted_correspondence_types
      authorize case_type, :can_add_case?

      builder = build_case(session: session, step: params[:step])

      @case = builder.build
      @s3_direct_post = S3Uploader.for(@case, 'requests')
      @back_link = back_link_url
    end

    def create
      authorize case_type, :can_add_case?
      default_disclosure_specialists_flag

      builder = build_case(
        session: session, 
        step: params[:current_step], 
        params: create_params
      )

      @case = builder.build

      @s3_direct_post = S3Uploader.for(builder.kase, 'requests')

      if builder.kase_ready_for_creation? 
        default_disclosure_specialists_flag

        service = CaseCreateService.new(
          user: current_user,
          case_type: case_type,
          params: create_params,
          prebuilt_case: builder.kase
        )
        service.call
        @case = service.case

        handle_case_service_result(service)
      else
        if builder.kase.valid_attributes?(create_params)
          go_next_step
        else
          render :new
        end
      end
    end

    def handle_case_service_result(service)
      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = service.message
        redirect_to new_case_assignment_path @case
      else
        @case = @case.decorate
        @s3_direct_post = S3Uploader.for(@case, 'requests')
        render :new
      end
    end

    def case_type
      Case::SAR::InternalReview
    end

    def build_case(session:, step:, params: nil)
      Builders::SteppedCaseBuilder.new(
        case_type: case_type,
        session: session,
        step: step,
        creator: current_user,
        params: params
      )
    end

    def default_disclosure_specialists_flag
      params[:sar_internal_review].merge!(flag_for_disclosure_specialists: 'yes')
    end

    def create_case
      @case.save
      session[session_state] = nil
      flash[:creating_case] = true
      flash[:notice] = "Case created successfully"
      make_case_a_triggered_case
      redirect_to new_case_assignment_path @case
    end

    def create_params
      create_sar_internal_review_params
    end

    def edit_params
      edit_sar_internal_review_params
    end

    def process_closure_params
      process_sar_internal_review_closure_params
    end

    def respond_params
      respond_sar_internal_review_params
    end

    def process_date_responded_params
      respond_sar_internal_review_params
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
      session_state = "#{case_type.type_abbreviation.downcase}_state".to_sym
      session[session_state] ||= {}
      params ||= {}
      session[session_state].merge! params
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
