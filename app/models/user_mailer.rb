class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'  
    @body[:url]  = "#{APP_URL}/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "#{APP_URL}/"
  end
  
  def reset_password(user)
    setup_email(user)
    @subject    += 'Your may reset your pasword'
    @body[:url]  = "#{APP_URL}/reset_password/#{user.activation_code}/?email=#{user.email}"
  end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "#{ADMIN_EMAIL}"
      @subject     = "[Manager] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
