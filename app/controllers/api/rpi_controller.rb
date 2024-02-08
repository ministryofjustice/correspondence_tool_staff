module Api
  class RpiController < ApiController
    # before_action :authenticate_request, except: :index

    class << self
      attr_accessor :json
     end

    def index
      render json: self.class.try(:json) || "no data"
    end

    def create
      # RequestPersonalInformationJob.perform_later(@decrypted_body)
      self.class.json = @decrypted_body
      render plain: "ok"
    end

    def render_unauthorized
      head :unauthorized
    end

  private

    def authenticate_request
      encrypted_payload = request.raw_post
      return render_unauthorized if encrypted_payload.blank?

      begin
        @decrypted_body = JSON.parse(JWE.decrypt(encrypted_payload, jwe_key), symbolize_names: true)
      rescue JWE::DecodeError => e
        Rails.logger.info("returning unauthorized due to JWE::DecodeError '#{e}'")
        render_unauthorized
      rescue JWE::InvalidData => e
        Rails.logger.error("returning unauthorized due to JWE::InvalidData (we could be missing the decryption key) '#{e}'")
        render_unauthorized
      end
    end

    def jwe_key
      "2d7eca8ec82b142b5736fa34d8e916dd9980f31ac2a176b5ae30662c0bdfdbdd7ccebebbab41a7907f4a151a187c76049c87c75bb9d23457eaa42f4bdcf0f573"
    end
  end
end
