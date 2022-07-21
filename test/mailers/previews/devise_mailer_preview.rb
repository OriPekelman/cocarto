class DeviseMailerPreview < ActionMailer::Preview
  def invitation_instructions
    Devise::Mailer.invitation_instructions(User.first, "__token__")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, "__token__")
  end
end
