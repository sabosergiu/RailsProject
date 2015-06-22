class VersionController < ApplicationController
  layout 'standard'
  before_action :authenticate_user!
  require 'zip'

  def view
    @backups = BackupArchive.all
  end

  def fix
    if (!params[:id] || !current_user.is_sysadmin?)
      flash[:alert] = "Invalid access or archive!"
      redirect_to version_path
      return
    end
    backup = BackupArchive.find_by(id: params[:id])
    if backup
      Document.transaction do
        zip_file = Zip::File.open("#{Rails.root}/backups/#{backup.filename}")
        xml_file = zip_file.get_input_stream('index.xml')
        xml = Nokogiri::XML(xml_file.read)
      #categories
        categories = xml.xpath("//categories//category")
        categories.each do |categ|
          id = categ.element_children[0].text.to_i
          update_category(id,categ.element_children[1].text,categ.element_children[2].text,false)
        end

      #users
        users = xml.xpath("//users//user")
        users.each do |user|
          id = user.element_children[0].text.to_i
          update_user(id,user.element_children[1].text,user.element_children[2].text,user.element_children[3].text,
                      user.element_children[4].text,user.element_children[5].text,false)
        end

      #documents
        documents = xml.xpath("//documents")
        documents[0].element_children.each do |document|
          id = document.element_children[0].text.to_i
          update_document(id,document.element_children[1].text,document.element_children[2].text,
                           document.element_children[6].text,document.element_children[9].text,
                           document.element_children[4].text,document.element_children[5].text,
                           document.element_children[7].text,document.element_children[8].text,zip_file,true)
        end

      end

    end
    flash[:notice] = "Database successfully updated"
    redirect_to version_path

  end

  def revert

    if (!params[:id] || !current_user.is_sysadmin?)
      flash[:alert] = "Invalid access or archive!"
      redirect_to version_path
      return
    end

    archive = BackupArchive.find_by(id: params[:id])
    if archive
      zip_file = Zip::File.open("#{Rails.root}/backups/#{archive.filename}")
      xml_file = zip_file.get_input_stream('index.xml')
      xml = Nokogiri::XML(xml_file.read)
      Document.transaction do
      #categories
        updated_categs = []
        categories = xml.xpath("//categories//category")
        categories.each do |categ|
          id = categ.element_children[0].text.to_i
          update_category(id,categ.element_children[1].text,categ.element_children[2].text,true)
          updated_categs.push(id)
        end

      #users
        updated_users = []
        users = xml.xpath("//users//user")
        users.each do |user|
          id = user.element_children[0].text.to_i
          update_user(id,user.element_children[1].text,user.element_children[2].text,user.element_children[3].text,
                      user.element_children[4].text,user.element_children[5].text,true)
          updated_users.push(id)
        end

      #documents
        updated_documents = []
        documents = xml.xpath("//documents")
        documents[0].element_children.each do |document|
          id = document.element_children[0].text.to_i
          update_document(id,document.element_children[1].text,document.element_children[2].text,
                           document.element_children[6].text,document.element_children[9].text,
                           document.element_children[4].text,document.element_children[5].text,
                           document.element_children[7].text,document.element_children[8].text,zip_file,true)
          updated_documents.push(id)
        end
      #Removing excess records
        Document.all.each do |doc|

          if !updated_documents.include?(doc.id)
            doc.remove_document
            doc.destroy
          end

        end

        User.all.each do |user|

          if !updated_users.include?(user.id)
            user.destroy
          end

        end

        Category.all.each do |categ|

          if !updated_categs.include?(categ.id)
            categ.destroy
          end

        end

      end
    end
    redirect_to version_path
    flash[:notice] = "Database succesfully reverted to the selected version!"
  end

  def delete
    if (!params[:id] || !current_user.is_sysadmin?)
      redirect_to version_path
      return
    end
    archive = BackupArchive.find_by(id: params[:id])
    if archive
      File.delete("#{Rails.root}/backups/#{archive.filename}")
      archive.destroy
    end
    redirect_to version_path
  end

  private
  def update_category(id,name,approved,force)
    #true for revert, false for fix
    cat = Category.find_by(id: id)

    if !cat
      cat = Category.new
      cat.id = id
      cat.name = name
      cat.approved = approved
      cat.save
    elsif force
      cat.name = name
      cat.approved = approved
      cat.save
    end

  end

  def update_document(id,name,desc,user_id,path,categ_id,deleted,uploaded_at,original,zip_file,force)
    doc = Document.find_by(id: id)

    if !doc
      doc = Document.new
      doc.id = id
      doc.name = name
      doc.description = desc
      doc.user = User.find_by(id: user_id.to_i)
      zip_file.extract(path,"#{Rails.root}/uploads/#{path}"){true}
      doc.document.store!(File.open("#{Rails.root}/uploads/#{path}"))
      doc.category = Category.find_by(id: categ_id)
      doc.deleted = deleted
      doc.uploaded_at = uploaded_at
      doc.original = original
      doc.save
    elsif force
      doc.name = name
      doc.description = desc
      doc.user = User.find_by(id: user_id.to_i)
      zip_file.extract(path,"#{Rails.root}/uploads/#{path}"){true}
      doc.document.store!(File.open("#{Rails.root}/uploads/#{path}"))
      doc.category = Category.find_by(id: categ_id.to_i)
      doc.deleted = deleted
      doc.uploaded_at = uploaded_at
      doc.original = original
      doc.save
    end

  end

  def update_user(id,email,encrypted_password,username,password,user_type,force)
    usr = User.find_by(id: id)

    if !usr
      usr = User.new
      usr.id = id
      usr.email = email
      usr.encrypted_password = encrypted_password
      usr.username = username
      usr.password = password
      usr.user_type = user_type
      usr.save
    elsif force
      usr.encrypted_password = encrypted_password
      usr.username = username
      usr.password = password
      usr.user_type = user_type
      usr.save
    end

  end

end
