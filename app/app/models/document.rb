class Document < ActiveRecord::Base
  mount_uploader :document, DocumentUploader
  belongs_to :category
  belongs_to :user

  def get_versions
    name=self.name.gsub(/\.(.*)/,'')
    time=self.uploaded_at
    ext=document.file.extension
    if ext=='png'
      return Document.where("name regexp '#{name}_[0-9]{4}x[0-9]{4}' and uploaded_at='#{time}' and original=false")
    else
      return Document.where("name like '#{name}.%' and uploaded_at='#{time}' and original=false")
    end
  end
end
