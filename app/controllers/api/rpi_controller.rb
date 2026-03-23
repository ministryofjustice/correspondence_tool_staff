module Api
  class RpiController < ApiController
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
      Sentry.capture_message "PersonalInformationRequest API (#{self.class.name}) failure --- ID: #{request&.id}, SubmissionId: #{submission_id}, Error: #{e.message}"
      Sentry.capture_exception(e)

      head :unprocessable_entity
    end

    def render_unauthorized
      head :unauthorized
    end

  private

    def authenticate_request
      encrypted_payload = request.raw_post
      return render_unauthorized if encrypted_payload.blank?

      begin
        @body = JSON.parse(JWE.decrypt(encrypted_payload, jwe_key), symbolize_names: true)
      rescue JWE::DecodeError => e
        Rails.logger.info("returning unauthorized due to JWE::DecodeError '#{e}'")
        render_unauthorized
      rescue JWE::InvalidData => e
        Rails.logger.error("returning unauthorized due to JWE::InvalidData (we could be missing the decryption key) '#{e}'")
        render_unauthorized
      end
    end

    def jwe_key
      Settings.rpi_jwe_key
    end
  end
end
