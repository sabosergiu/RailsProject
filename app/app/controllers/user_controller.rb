class UserController < ApplicationController
  layout "standard"
  before_action :authenticate_user!
  MIN_LENGTH = 4

  def list

    if current_user.is_admin?
      @users = User.where("user_type = '#{User.user_types[:user]}' or user_type = '#{User.user_types[:moderator]}' or id = ?",current_user.id)
    end

    if current_user.is_sysadmin?
      @users = User.all
    end

  end

  def edit

    if (current_user.is_moderator? || current_user.is_user?)
      @user = current_user
      return
    end

    if params[:id]
      @user = User.find_by(id: params[:id])
      if current_user.is_sysadmin?
        return
      end
    else
      @user = current_user
      return
    end

    if (!@user || !(current_user.is_admin? && (params[:id].to_i == current_user.id || @user.is_user? || @user.is_moderator?)))
      @user = nil
    end

  end

  def update

    if (current_user.is_user? || current_user.is_moderator?)
        flash[:notice] = "User type"
        old_pass = User.new(:password => params[:user][:old_password]).encrypted_password

        if (params[:user][:password] == params[:user][:con_pass]  && current_user.valid_password?(params[:user][:old_password]) && params[:user][:password].length >= MIN_LENGTH)
          current_user.password = params[:user][:password]
          flash[:notice] = "Password updated"
          current_user.save
        else
          flash[:alert] = "Invalid password length or passwords do not match!"
        end

        redirect_to user_edit_path
        return
    end

    user = User.find_by(id: params[:user][:id])

    if user

      if (current_user.is_admin? || current_user.is_sysadmin?)
        user.user_type = params[:user_type]
        flash[:notice] = "User type"

        if (params[:user][:password] == params[:user][:con_pass] && params[:user][:password].length >= MIN_LENGTH)
          user.password = params[:user][:password]
          flash[:notice]<<", user password"
        end
          flash[:notice]<<" updated for #{params[:user][:email]}!"
        if ((current_user.is_admin? && (user.is_user? || user.is_moderator? || user.id == current_user.id)) || current_user.is_sysadmin?)
          user.save
        end

      end

    else
      flash[:alert] = "No user found!"
    end

    redirect_to user_path

  end
end
