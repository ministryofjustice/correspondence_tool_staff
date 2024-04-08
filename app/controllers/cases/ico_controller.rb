module Cases
  class ICOController < CasesController
    include ICOCasesParams
    include NewCase
    include ReopenICOCase

    before_action -> { set_case(params[:id]) }, only: [:record_late_team]

    def initialize
      @correspondence_type = CorrespondenceType.ico
      @correspondence_type_key = "ico"

      super
    end

    def new
      authorize case_type, :can_add_case?

      permitted_correspondence_types
      new_case_for @correspondence_type
    end

    def new_linked_cases_for
      set_correspondence_type(params.fetch(:correspondence_type))
      @link_type = params[:link_type].strip

      respond_to do |format|
        format.js do
          if process_new_linked_cases_for_params
            response = render_to_string(
              partial: "cases/#{@correspondence_type_key}/case_linking/linked_cases",
              locals: {
                linked_cases: @linked_cases.map(&:decorate),
                link_type: @link_type,
              },
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
        render "/cases/ico/late_team"
      end
    end

    # Can only be determined during case creation. Note defaulting to FOI
    # to allow subsequent validation to be performed during Case#Create
    def case_type
      return Case::ICO::FOI if original_case_id.blank?

      Case::Base.find(original_case_id).class.ico_model
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

    def record_late_team_params(correspondence_type)
      if correspondence_type == "ICO"
        record_late_team_ico_params
      else
        raise "#record_late_team_params only valid for ICO cases"
      end
    end

    def original_case_id
      @original_case_id ||= if params && params[:ico].present? && params[:ico][:original_case_ids].present?
                              params[:ico][:original_case_ids].first
                            end
    end
  end
end
