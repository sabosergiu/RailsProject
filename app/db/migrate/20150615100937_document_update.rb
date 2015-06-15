class DocumentUpdate < ActiveRecord::Migration
  def change
    add_column :documents, :original, :boolean, :default => false
  end
end
