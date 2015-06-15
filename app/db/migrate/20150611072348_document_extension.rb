class DocumentExtension < ActiveRecord::Migration
  def change
    add_column :documents, :deleted, :boolean
    add_column :documents, :user_id, :integer
    add_column :documents, :uploaded_at, :datetime, default: false
  end
end
