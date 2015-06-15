class DocumentModifications < ActiveRecord::Migration
  def change
    add_index :documents, :document, :unique=>true
    add_column :documents, :category_id, :integer
  end
end
