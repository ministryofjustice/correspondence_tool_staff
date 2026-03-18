module Api
  class RpiV2Controller < ApiController
    before_action :authenticate_request, only: :create

    def create
      request = PersonalInformationRequest.build(@body)
      request.save!

      RequestPersonalInformationJob.perform_later(request.id)

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
