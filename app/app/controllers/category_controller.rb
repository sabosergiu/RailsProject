class CategoryController < ApplicationController
  layout 'standard'
  before_action :authenticate_user!

  def list
    if current_user.is_sysadmin?
      @categs=Category.all
    else
      @categs=Category.where("approved = true")
    end
  end

  def change_validation
    if current_user.is_sysadmin?
      begin
        @categ=Category.find(params[:id])
      rescue
        redirect_to action: "list"
        return
      end
      if @categ!=nil
        @categ.approved= !@categ.approved
        @categ.save
      end
    end
    redirect_to action: "list"
  end

  def delete
    #
    @categ=Category.find(params[:id])
    @categ.destroy
  end

  def add
    if params[:category][:name]==nil or params[:category][:name]==""
      redirect_to action: "list"
      return
    end
    @categ=Category.new
    @categ.name=params[:category][:name] 
    if current_user.is_sysadmin?
      @categ.approved=true
    end
    @categ.save
    redirect_to action: "list"
  end
end
