class Workflows::Conditionals
  def initialize(user:, kase:)
    @user = user
    @kase = kase
  end

  def remove_response
    if @kase.attachments.size == 0
      'drafting'
    else
      'awaiting_dispatch'
    end
  end
end
