class SessionController < ApplicationController
	include SessionHelper
	def new
	end

	def create
		user=User.find_by(username: params[:session][:username])
		if user && user.password==params[:session][:password]
			log_in(user)
			redirect_to :action => "list"
		else
			redirect_to :action => "new"
		end
	end

	def delete
		log_out
		redirect_to :action => "new"	
	end

	def list
		@users=User.all
	end
end
