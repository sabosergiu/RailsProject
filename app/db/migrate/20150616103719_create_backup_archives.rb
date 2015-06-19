class CreateBackupArchives < ActiveRecord::Migration
  def change
    create_table :backup_archives do |t|
      t.string :filename
      t.timestamp :saved_at, null: false
    end
  end
end
