class CategoryController < ApplicationController
  layout 'standard'
  before_action :authenticate_user!

  def list
    @categs=Category.where("approved = true")
  end

  def add
    #@categ=Category.new
    Category.create(name: "as")
    puts @categ.valid? #=> false 
    puts @categ.errors.full_messages #=> []
    @categ.save!
return
    puts @categ.inspect

    if params[:category][:name]!=nil
      @categ.save
    end
  end
end
