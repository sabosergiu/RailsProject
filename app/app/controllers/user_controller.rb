class UserController < ApplicationController
  layout "standard"
  before_action :authenticate_user!

  def list
    if current_user.is_admin?
      @users=User.where("user_type = null or user_type='moderator' or id=?",current_user.id)
    end
    if current_user.is_sysadmin?
      @users=User.all
    end
  end

  def edit
    if params[:id]!=nil
      begin
        @user=User.find(params[:id])
      rescue
        @user=nil
        return
      end
      if !(current_user.is_admin? and (params[:id].to_i==current_user.id or @user.is_simple_user? or @user.is_moderator?))
        @user=nil
      end
    end
  end

  def update
    if params[:user][:password]==params[:user][:con_pass]
      @user=User.find(params[:user][:id])
      @user.password=params[:user][:password]
      @user.user_type=params[:user_type]
      @user.save
    end
    redirect_to user_list_path
  end
end
