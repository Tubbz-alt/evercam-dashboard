module SessionsHelper
  def sign_in(user)
    session[:user] = (user ? user.email : nil)
    @current_user = user
  end

  def sign_out
    session.clear
    @current_user = nil
  end

  def signed_in?
    !@current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.where(email: session[:user]).first
  end
end
