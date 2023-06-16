module DeviseHelper
  # overrides Devise library method to enable error messages to show correctly
  def devise_error_messages!
    if resource.errors.full_messages.any?
      flash.now[:alert] = resource.errors.full_messages.join("\n")
    end
    ""
  end
end
