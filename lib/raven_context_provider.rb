class RavenContextProvider

  def self.set_context(controller = nil)
    if controller.respond_to?(:current_user) && controller.current_user.present?
      user = controller.current_user
      Raven.user_context(id: user.id, email: user.email)
    end

    Raven.extra_context(
      host_environment: ENV['ENV'] || 'Not set',
      build_date: ENV['APP_BUILD_DATE'],
      git_commit_sha: ENV['APP_GIT_COMMIT']
    )

  end
end
