class Users < ActiveRecord::Migration
  def up
	create_table :users do |t|
		t.column :username, :string, :limit => 20, :null => false
		t.column :password, :string, :limit => 20, :null => false
	end
	User.create :username => "user1", :password => "1234"
	User.create :username => "user2", :password => "456"
	User.create :username => "user3", :password => "PaSs"
  end
  def down
	drop_table :users
  end
end
