class HomeController < ApplicationController
  layout 'standard'
  before_action :authenticate_user!
  def start
    
  end
end
