class CustomDeviseFailure < Devise::FailureApp
  def i18n_message(default = nil)
    message = warden_message || default || :unauthenticated

    if message == :inactive
      # Check if user exists and is suspended
      user = User.find_by(email: request.params.dig("user", "email"))
      if user && user.suspended?
        return :suspended
      end
    end

    message
  end
end
