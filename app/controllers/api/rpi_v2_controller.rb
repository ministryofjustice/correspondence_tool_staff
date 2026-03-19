module Api
  class RpiV2Controller < ApiController
    before_action :authenticate_request, only: :create

    def create
      submission_id = PersonalInformationRequest.submission_id(@body)
      @personal_information_request = PersonalInformationRequest.create!(submission_id:)
      @personal_information_request.build(@body)

      RequestPersonalInformationJob.perform_now(@personal_information_request.id, @body)
      head :ok
    rescue StandardError => e
      if @personal_information_request
        @personal_information_request.update!(processed: false, log: "#{e.message}\n#{e.backtrace[0..5].join("\n")}")
      end

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
