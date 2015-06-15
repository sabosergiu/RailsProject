class UserController < ApplicationController
  layout "standard"
  before_action :authenticate_user!

  def list
    if current_user.is_admin?
      @users=User.where("user_type = 'user' or user_type='moderator' or id=?",current_user.id)
    end
    if current_user.is_sysadmin?
      @users=User.all
    end
  end

  def edit
    if params[:id]!=nil
      @user=User.find_by(id: params[:id])
      return
    end
    if !(current_user.is_admin? and (params[:id].to_i==current_user.id or @user.is_simple_user? or @user.is_moderator?))
      @user=nil
    end
  end

  def update
      
      @user=User.find(params[:user][:id])
      @user.user_type=params[:user_type]
    if params[:user][:password]==params[:user][:con_pass] and params[:user][:password]!=""
      @user.password=params[:user][:password]
    end
    @user.save
    redirect_to user_list_path
  end
end
