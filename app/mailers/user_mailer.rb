class UserMailer < ActionMailer::Base
   default from: "noreply@evercam.io"

   # This method dispatches an email whenever a user chooses to share a camera
   # with a user that doesn't currently possess an Evercam account.
   def sign_up_to_share_email(email, camera_id, user, key)
      @camera_id = camera_id
      @user      = user
      @key       = key
      mail(to: email, subject: "#{user.username} has shared a camera with you")
   end

   # This method dispatches an email to an Evercam user whenever another user
   # shares a camera with them.
   def camera_shared_notification(email, camera_id, user)
      @camera_id = camera_id
      @user      = user
      mail(to: email, subject: "#{user.username} has shared a camera with you")
   end

   def password_reset(email, user, token)
      @token    = token
      @user     = user
      mail(to: email, subject: "#{user.username} has requested password reset")
   end
end
