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
      @categ = Category.find_by(id: params[:id])
      if @categ
        if @categ.approved
          flash[:notice] = "Category succesfully invalidated!"
        else
          flash[:notice] = "Category succesfully validated!"
        end
        @categ.approved = !@categ.approved
        @categ.save
      else
        flash[:alert] = "Category not found!"
      end
    else
      flash[:alert] = "Invalid acces!"
    end
    redirect_to action: "list"
  end

  def add

    if (!params[:category][:name] || params[:category][:name] == "")
      redirect_to action: "list"
      flash[:alert] = "The category was not added! Empty name!"
      return
    end

    @categ = Category.new
    @categ.name = params[:category][:name] 

    if current_user.is_sysadmin?
      @categ.approved = true
    end

    @categ.save
    flash[:notice] = "Category succesfully added!"
    redirect_to action: "list"
  end
end
