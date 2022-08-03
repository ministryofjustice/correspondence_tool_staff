module Cases
  class IcoSarController < IcoController
    # def new
    #   authorize case_type, :can_add_case?

    #   permitted_correspondence_types
    #   new_case_for @correspondence_type, case_type
    # end
    before_action -> { set_decorated_case(params[:id]) }, only: [
      :record_further_action,
      :require_further_action
    ]

    def record_further_action
      authorize @case, :can_record_further_action?

      set_permitted_events
      read_info_from_session
      @s3_direct_post = S3Uploader.for(@case, 'requests')
      render 'cases/ico_foi/record_further_action'
    end

    def case_type
      Case::ICO::SAR
    end

    private

    def session_info_key
      "ico_sar_requir_further_action"
    end

    def session_persist_state(params)
      session[session_info_key] ||= {}
      params ||= {}
      clear_up_files_params
      session[session_info_key].merge! params
    end

    def clear_up_files_params
      # The current implementation of front-end ui for uploading the files
      #  doesn't have the function of loading files which has been uploaded
      #  so we cannot keep this info in session
      if session[session_info_key].present?
        if session[session_info_key][:uploaded_request_files].present?
          session[session_info_key].delete(:uploaded_request_files)
        end
        if session[session_info_key]["uploaded_request_files"].present?
          session[session_info_key].delete("uploaded_request_files")
        end
      end
    end

    def read_info_from_session
      clear_up_files_params
      if session[session_info_key].present?
        @case.assign_attributes(session[session_info_key])
      end
    end
  end
end
