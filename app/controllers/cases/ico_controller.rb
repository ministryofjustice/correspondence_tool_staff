module Cases
  class IcoController < CasesController
    include ICOCasesParams
    include NewCase

    before_action -> { set_case(params[:id]) }, only: [:record_late_team]

    def new
      @correspondence_type_key = 'ico'
      permitted_correspondence_types
      new_case_for CorrespondenceType.ico
    end

    def create
      create_case_for_type CorrespondenceType.ico, 'ico'
    end

    def new_linked_cases_for
      set_correspondence_type(params.fetch(:correspondence_type))
      @link_type = params[:link_type].strip

      respond_to do |format|
        format.js do
          if process_new_linked_cases_for_params
            response = render_to_string(
              partial: "cases/#{ @correspondence_type_key }/case_linking/linked_cases",
              locals: {
                linked_cases: @linked_cases.map(&:decorate),
                link_type: @link_type,
              }
            )

            render status: :ok, json: { content: response, link_type: @link_type }.to_json

          else
            render status: :bad_request,
              json: { linked_case_error: @linked_case_error,
                link_type: @link_type }.to_json
          end
        end
      end
    end

    def record_late_team
      authorize @case, :can_respond?
      @case.prepare_for_recording_late_team
      params = record_late_team_params(@case.type_abbreviation)
      if @case.update(params)
        @case.respond(current_user)
        redirect_to case_path
      else
        @team_collection = CaseTeamCollection.new(@case)
        render '/cases/ico/late_team'
      end
    end

    def create_params
      create_ico_params
    end

    def edit_params
      edit_ico_params
    end

    def process_closure_params
      process_ico_closure_params
    end

    def respond_params
      respond_ico_params
    end

    def process_date_responded_params
      ico_close_date_responded_params
    end

    private

    def determine_overturned_ico_class(original_appeal_id)
      original_appeal_case = Case::ICO::Base.find original_appeal_id
      case original_appeal_case.type
      when 'Case::ICO::FOI'
        Case::OverturnedICO::FOI
      when 'Case::ICO::SAR'
        Case::OverturnedICO::SAR
      else
        raise ArgumentError.new 'Invalid case type for original ICO appeal'
      end
    end

    def record_late_team_params(correspondence_type)
      if correspondence_type == 'ICO'
        record_late_team_ico_params
      else
        raise '#record_late_team_params only valid for ICO cases'
      end
    end
  end
end
