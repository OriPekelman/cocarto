class DeviseMailerPreview < ActionMailer::Preview
  def invitation_instructions
    user_fixture = User.first
    user_fixture.invited_by = User.second
    Devise::Mailer.invitation_instructions(user_fixture, "__token__")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, "__token__")
  end
end
