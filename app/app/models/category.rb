class Category < ActiveRecord::Base
  validates_presence_of name
  
  def is_confirmed?
    approved
  end
end
