module Api
  class RpiV2Controller < ApiController
    before_action :authenticate_request, only: :create

    def create
      submission_id = PersonalInformationRequest.submission_id(@body)
      request = PersonalInformationRequest.create!(submission_id:)
      request.build(@body)

      RequestPersonalInformationJob.perform_later(request.id, @body)

      head :ok
    rescue StandardError => e
      request&.failed(e)

      # Deliberately capture separate Sentry error for individual submissions
      Sentry.capture_message "PersonalInformationRequest API failure --- ID: #{request&.id}, SubmissionId: #{submission_id}, Error: #{e.message}"
      Sentry.capture_exception(e)

      head :unprocessable_entity
    end

    def render_unauthorized
      head :unauthorized
    end

  private

    def authenticate_request
      payload = request.raw_post
      return render_unauthorized if payload.blank?

      @body = JSON.parse(payload, symbolize_names: true)
    end
  end
end
