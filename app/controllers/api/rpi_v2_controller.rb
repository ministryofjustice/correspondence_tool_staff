module Api
  class RpiV2Controller < ApiController
    before_action :authenticate_request, only: :create

    def create
      RequestPersonalInformationJob.perform_later(@body)
      head :ok
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
