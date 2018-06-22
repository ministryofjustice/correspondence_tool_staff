module ViewSpecHelpers
  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end
end
