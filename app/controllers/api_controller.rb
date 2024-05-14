class ApiController < ActionController::API
  before_action { SentryContextProvider.set_context(self) }
end
