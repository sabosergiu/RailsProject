class Category < ActiveRecord::Base
   validates :name, presence: true
   has_many :documents
  
  def is_confirmed?
    approved
  end
end
