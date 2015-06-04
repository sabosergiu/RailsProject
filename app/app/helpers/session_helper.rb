module SessionHelper
	def log_in(user)
		session[:user_id]=user.id
	end
	def log_out
		reset_session
	end
end
