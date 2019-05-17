module Cases
  class ClosureController < BaseController
    def close
      # prepopulate date if it was entered by the KILO
      authorize @case, :can_close_case?
      if @case.ico?
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      end
      set_permitted_events
    end

    def edit_closure
      authorize @case, :update_closure?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @case = @case.decorate
      @team_collection = CaseTeamCollection.new(@case)
    end

    def process_date_responded
      authorize @case, :can_close_case?
      @case = @case.decorate

      @case.prepare_for_respond
      if !@case.update process_date_responded_params(@correspondence_type_key)
        render :close
      else
        @team_collection = CaseTeamCollection.new(@case)
        @case.update(late_team_id: @case.responding_team.id)
        redirect_to closure_outcomes_case_path(@case)
      end
    end

    def closure_outcomes
      @case = @case.decorate
      authorize @case, :can_close_case?
      if @case.ico?
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      end
      @team_collection = CaseTeamCollection.new(@case)
    end

    def process_closure
      authorize @case, :can_close_case?
      @case = @case.decorate
      close_params = process_closure_params(@case.type_abbreviation)
      service = CaseClosureService.new(@case, current_user, close_params)
      service.call
      if service.result == :ok
        set_permitted_events
        flash[:notice] = service.flash_message
        redirect_to case_path(@case)
      else
        set_permitted_events
        @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
        @team_collection = CaseTeamCollection.new(@case)
        render :closure_outcomes
      end
    end

    def respond_and_close
      authorize @case
      @case.date_responded = nil
      set_permitted_events
      render :close
    end

    def process_respond_and_close
      authorize @case, :respond_and_close?
      @case.prepare_for_close
      close_params = process_closure_params(@case.type_abbreviation)

      if @case.update(close_params)
        @case.respond_and_close(current_user)
        set_permitted_events
        @close_flash_message = t('notices.case_closed')
        if @permitted_events.include?(:update_closure)
          flash[:notice] = "#{@close_flash_message}. #{ get_edit_close_link }".html_safe
        else
          flash[:notice] = @close_flash_message
        end
        redirect_to case_path(@case)
      else
        set_permitted_events
        @team_collection = CaseTeamCollection.new(@case)
        render :closure_outcomes
      end
    end

    def update_closure
      authorize @case
      close_params = process_closure_params(@case.type_abbreviation)
      @case.prepare_for_close

      service = UpdateClosureService.new(@case, current_user, close_params)
      service.call
      if service.result == :ok
        set_permitted_events
        flash[:notice] = t('notices.closure_details_updated')
        redirect_to case_path(@case)
      else
        @case = @case.decorate
        render :edit_closure
      end
    end

    def respond
      authorize @case, :can_respond?
      set_correspondence_type(@case.type_abbreviation.downcase)
    end

    def confirm_respond
      authorize @case, :can_respond?
      params = respond_params(@correspondence_type_key)
      service = MarkResponseAsSentService.new(@case, current_user, params)
      service.call
      case service.result
      when :ok
        flash[:notice] = t('.success')
        redirect_to case_path(@case)
      when :late
        @team_collection = CaseTeamCollection.new(@case)
        render '/cases/ico/late_team'
      when :error
        set_correspondence_type(@case.type_abbreviation.downcase)
        render :respond
      else
        raise 'unexpected result from MarkResponseAsSentService'
      end
    end

    private

    def process_closure_params(correspondence_type)
      case correspondence_type
      when 'FOI', 'OVERTURNED_FOI' then process_foi_closure_params
      when 'SAR', 'OVERTURNED_SAR' then process_sar_closure_params
      when 'ICO' then process_ico_closure_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def respond_params(correspondence_type)
      case correspondence_type
      when 'foi' then respond_foi_params
      when 'sar' then respond_sar_params
      when 'ico' then respond_ico_params
      when 'overturned_foi', 'overturned_sar' then respond_overturned_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def process_date_responded_params(correspondence_type)
      case correspondence_type
      when 'foi' then respond_foi_params
      when 'sar' then respond_sar_params
      when 'ico' then ico_close_date_responded_params
      when 'overturned_foi', 'overturned_sar' then respond_overturned_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def get_edit_close_link
      edit_close_link = edit_closure_case_path(@case)
      view_context.link_to "Edit case closure details",
                           edit_close_link,
                           { class: "undo-take-on-link" }
    end

  end
end
