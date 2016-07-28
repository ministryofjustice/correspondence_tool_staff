module Api

  class ApplicationController < ActionController::Base
    protect_from_forgery with: :null_session

    before_action :authenticate

    private

    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        ENV['WEB_FORM_AUTH_TOKEN'] == token
      end
    end

  end

end
