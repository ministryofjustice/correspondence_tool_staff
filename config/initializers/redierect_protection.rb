# Disable Protection from open redirect attacks in `redirect_back_or_to` and `redirect_to`.
Rails.application.config.action_controller.raise_on_open_redirects = false
