class ChangedConstraints < ActiveRecord::Migration
  def change
    change_column :users, :username, :string, :null => true
    change_column :users, :password, :string, :null => true
  end
end
