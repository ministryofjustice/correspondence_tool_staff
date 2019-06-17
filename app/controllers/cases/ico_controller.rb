module Cases
  class IcoController < CasesController
    include ICOCasesParams
    include NewCase

    before_action :set_case, only: [:record_late_team]

    def new
      @correspondence_type_key = 'ico'
      new_case_for CorrespondenceType.ico
    end

    def create
      create_case_for_type CorrespondenceType.ico, 'ico'
    end

    # this action is only used for ICO cases
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

    # TODO: MOVE TO NEW CONTROLLER
    # The new action for overturned ICO cases is a separate action because it is a bit different
    #
    # from the other case types:
    #
    #   - it takes parameter (the id of the ICO appeal from which it is to be created)
    #
    # We can consider merging it back in to the generalised new, and having logic there to work out what to do
    # and what page to show, but am leaving it for now.
    #
    def new_overturned_ico
      overturned_case_class = determine_overturned_ico_class(params[:id])
      authorize overturned_case_class
      service = NewOverturnedIcoCaseService.new(params[:id])
      service.call
      if service.error?
        @case = service.original_ico_appeal.decorate
        render :show, :status => :bad_request
      else
        @case = service.overturned_ico_case.decorate
        @original_ico_appeal = service.original_ico_appeal
        set_correspondence_type(overturned_case_class.type_abbreviation.downcase)
        render :new
      end
    end

    def create_params
      create_ico_params
    end

    def edit_params
      edit_ico_params
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
