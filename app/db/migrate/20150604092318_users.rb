class Users < ActiveRecord::Migration
  def up
	create_table :users do |t|
		t.column :username, :string, :limit => 20, :null => false
		t.column :password, :string, :limit => 20, :null => false
	end
  end
  def down
	drop_table :users
  end
end
