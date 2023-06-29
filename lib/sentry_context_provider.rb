class SentryContextProvider
  def self.set_context(controller = nil)
    if controller.respond_to?(:current_user) && controller.current_user.present?
      user = controller.current_user
      Sentry.set_user(id: user.id, email: user.email)
    end

    Sentry.set_extras(
      host_environment: ENV["ENV"] || "Not set",
      build_date: ENV["APP_BUILD_DATE"],
      git_commit_sha: ENV["APP_GIT_COMMIT"],
    )
  end
end
