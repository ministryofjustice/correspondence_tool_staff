module Api
  class RpiController < ApiController
    before_action :authenticate_request, except: :index

    class << self
      attr_accessor :json
     end

    def index
      render json: self.class.try(:json) || "no data"
    end

    def create
      self.class.json = @decrypted_body
      rpi_service = RequestPersonalInformationService.new(@decrypted_body)
      ActionNotificationsMailer.rpi_email(rpi_service.build).deliver_now
      head :ok
    end

    def render_unauthorized
      head :unauthorized
    end

  private

    def authenticate_request
      encrypted_payload = request.raw_post
      return render_unauthorized if encrypted_payload.blank?

      begin
        @decrypted_body = JSON.parse(JWE.decrypt(encrypted_payload, jwe_key))
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
