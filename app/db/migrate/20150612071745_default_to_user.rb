class DefaultToUser < ActiveRecord::Migration
  def change
    change_column :users, :user_type, :string, :default => "user"
  end
end
