module Api
  class RpiV2Controller < RpiController
  private

    def authenticate_request
      payload = request.raw_post
      return render_unauthorized if payload.blank?

      @body = JSON.parse(payload, symbolize_names: true)
    end
  end
end
