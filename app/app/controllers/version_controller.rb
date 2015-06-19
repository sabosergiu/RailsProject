class VersionController < ApplicationController
  layout 'standard'
  before_action :authenticate_user!
  require 'zip'

  def view
    @backups=BackupArchive.all
  end

  def fix
    if params[:id]==nil or !current_user.is_sysadmin?
      flash[:alert]="Invalid access or archive!"
      redirect_to version_path
      return
    end
    backup=BackupArchive.find_by(id: params[:id])
    if backup!=nil
      Document.transaction do
        zip_file= Zip::File.open("#{Rails.root}/backups/#{backup.filename}")
        xml_file=zip_file.get_input_stream('index.xml')
        xml=Nokogiri::XML(xml_file.read)
      #categories
        categories=xml.xpath("//categories//category")
        categories.each do |categ|
          id=categ.element_children[0].text.to_i
          cat=Category.find_by(id: id)
          if cat==nil
            cat=Category.new
            cat.id=id
            cat.name=categ.element_children[1].text
            cat.approved=categ.element_children[2].text
            cat.save
          end
        end
      #
      #users
        users=xml.xpath("//users//user")
        users.each do |user|
          id=user.element_children[0].text.to_i
          usr=User.find_by(id: id)
          if usr==nil
            usr=User.new
            usr.id=id
            usr.email=user.element_children[1].text
            usr.encrypted_password=user.element_children[2].text
            usr.username=user.element_children[3].text
            usr.password=user.element_children[4].text
            usr.user_type=user.element_children[5].text
            usr.save
          end
        end
      #
      #documents
        documents=xml.xpath("//documents")
        documents[0].element_children.each do |document|
          id=document.element_children[0].text.to_i
          doc=Document.find_by(id: id)
          if doc==nil
            doc=Document.new
            doc.id=id
            doc.name=document.element_children[1].text
            doc.description=document.element_children[2].text
            doc.user=User.find_by(id: document.element_children[6].text.to_i)
            path=document.element_children[9].text
            zip_file.extract(path,"#{Rails.root}/uploads/#{path}"){true}
            doc.document.store!(File.open("#{Rails.root}/uploads/#{path}"))
            doc.category=Category.find_by(id: document.element_children[4].text.to_i)
            doc.deleted=document.element_children[5].text
            doc.uploaded_at=document.element_children[7].text
            doc.original=document.element_children[8].text
            doc.save
          end
        end
      #raise 'err'
      end
    end
    flash[:notice]="Database successfully updated"
    redirect_to version_path
  end

  def revert
    if params[:id]==nil or !current_user.is_sysadmin?
      flash[:alert]="Invalid access or archive!"
      redirect_to version_path
      return
    end
    archive=BackupArchive.find_by(id: params[:id])
    if archive!=nil
      zip_file=Zip::File.open("#{Rails.root}/backups/#{archive.filename}")
      xml_file=zip_file.get_input_stream('index.xml')
      xml=Nokogiri::XML(xml_file.read)
      Document.transaction do
      #categories
        updated_categs=[]
        categories=xml.xpath("//categories//category")
        categories.each do |categ|
          id=categ.element_children[0].text.to_i
          cat=Category.find_by(id: id)
            if cat==nil
            cat=Category.new
            cat.id=id
          end
          cat.name=categ.element_children[1].text
          cat.approved=categ.element_children[2].text
          cat.save
          updated_categs.push(id)
        end
      #
      #users
        updated_users=[]
        users=xml.xpath("//users//user")
        users.each do |user|
          id=user.element_children[0].text.to_i
          usr=User.find_by(id: id)
          if usr==nil
            usr=User.new
            usr.id=id
            usr.email=user.element_children[1].text
          end
          usr.encrypted_password=user.element_children[2].text
          usr.username=user.element_children[3].text
          usr.password=user.element_children[4].text
          usr.user_type=user.element_children[5].text
          usr.save
          updated_users.push(id)
        end
      #
      #documents
        updated_documents=[]
        documents=xml.xpath("//documents")
        documents[0].element_children.each do |document|
          id=document.element_children[0].text.to_i
          doc=Document.find_by(id: id)
          if doc==nil
            doc=Document.new
            doc.id=id
          end
          doc.name=document.element_children[1].text
          doc.description=document.element_children[2].text
          doc.user=User.find_by(id: document.element_children[6].text.to_i)
          path=document.element_children[9].text
          zip_file.extract(path,"#{Rails.root}/uploads/#{path}"){true}
          doc.document.store!(File.open("#{Rails.root}/uploads/#{path}"))
          doc.category=Category.find_by(id: document.element_children[4].text.to_i)
          doc.deleted=document.element_children[5].text
          doc.uploaded_at=document.element_children[7].text
          doc.original=document.element_children[8].text
          doc.save
          updated_documents.push(id)
        end
      ##Removing excess records
      #documents
        Document.all.each do |doc|
          if !updated_documents.include?(doc.id)
            doc.remove_document
            doc.destroy
          end
        end
      #user
        User.all.each do |user|
          if !updated_users.include?(user.id)
            user.destroy
          end
        end
      #category
        Category.all.each do |categ|
          if !updated_categs.include?(categ.id)
            categ.destroy
          end
        end
      ##
      end
    end
    redirect_to version_path
    flash[:notice]="Database succesfully reverted to the selected version!"
  end

  def delete
    if params[:id]==nil or !current_user.is_sysadmin?
      redirect_to version_path
      return
    end
    archive=BackupArchive.find_by(id: params[:id])
    if archive!=nil
      File.delete("#{Rails.root}/backups/#{archive.filename}")
      archive.destroy
    end
    redirect_to version_path
  end

end
