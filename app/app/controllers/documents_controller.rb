class DocumentsController < ApplicationController
  layout 'standard'
  include DocumentHelper
  include ResamplePng
  before_action :authenticate_user!
  #
  #"_png__0050x0050.png".gsub(/(?<=._)[^}]*(?=x)/,'')
  def new
    @file=Document.new
    if current_user.is_sysadmin?
      if params[:categ]!=nil
        @docs=Document.where("category_id =#{params[:categ]} and original=true")
        return
      end
      @docs=Document.all
      return
    end
    if params[:categ]!=nil
      @docs=Document.where("category_id =#{params[:categ]} and deleted=false and original=true")
      return
    end
    @docs=Document.where("deleted=false and original=true")
  end

  def change_state
    if params[:id]!=nil and (current_user.is_sysadmin? or current_user.is_admin?)
      @doc=Document.find_by(id: params[:id])
      if @doc!=nil
        @doc.deleted=!@doc.deleted
        @doc.save
      end
    end
    redirect_to documents_path
  end

  def force_delete
    if params[:id]==nil or !current_user.is_sysadmin?
      redirect_to documents_path
      return
    end
    @doc=Document.find_by(id: params[:id])
    if @doc!=nil
      @extension=@doc.document.file.extension
      @name=@doc.document.file.filename.gsub(/\.(.*)/,'')
      @path="#{Rails.root}/uploads/#{@doc.user.email}/"
      @doc.remove_document
      @doc.destroy
    end
    redirect_to documents_path
  end

  def create
    @file=Document.new(document_params)
    if @file.document.file==nil
      redirect_to documents_path
      return
    end
    @file.original=true
    @file.user=current_user
    @time=Time.now
    @file.uploaded_at=@time
    @file.deleted=false
    @file.name = @file.document.file.filename
    @categ=Category.find_by(id: params[:category][:id])
    @file.category=@categ
    @file.save
    @name=params[:document][:document].original_filename.gsub(/\.(.*)/,'')
    @sanit_name=DocumentHelper.sanitize(@name)
    @file_name=@file.document.file.filename.gsub(/\.(.*)/,'')
    #for creating conversions
    @extension=@file.document.file.extension
    if ['xls','csv','ots','ods'].include?(@extension.downcase)
      ['xls','csv','ots','ods','pdf'].each do |ext|
        if ext==@extension
          next
        end
        ret=`unoconv -f #{ext} #{Rails.root}/uploads/#{current_user.email}/#{@file.document.file.filename}`
        if !ret
          next
        end
        @new_doc = Document.new
        @new_doc.name="#{@sanit_name}.#{ext}"
        @new_doc.user=current_user
        @new_doc.category=@categ#Category.find_by(name: params[:category][:name])
        @new_doc.uploaded_at=@time
        @new_doc.deleted=false
        @new_doc.document.store!(File.open("#{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}"))        
        @new_doc.save!
      end
    end
    #for creating file conversion for video formats
    if ['mp4','avi','mpeg','mkv'].include?(@extension.downcase)
      ['mp4','avi','mpeg','mkv'].each do |ext|
        if ext==@extension
          next
        end
        ret=`ffmpeg -i #{Rails.root}/uploads/#{current_user.email}/#{@file.document.file.filename} -strict -2 #{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}`
        if !ret
          next
        end
        @new_doc = Document.new
        @new_doc.name="#{@sanit_name}.#{ext}"
        @new_doc.user=current_user
        @new_doc.category=@categ
        @new_doc.uploaded_at=@time
        @new_doc.deleted=false
        @new_doc.document.store!(File.open("#{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}"))        
        @new_doc.save!
      end
    end
    #for creating file conversion for audio formats
    if ['mp3','wav','ogg','flac'].include?(@extension.downcase)
      ['mp3','wav','ogg','flac'].each do |ext|
        if ext==@extension
          next
        end
        ret=`sox #{Rails.root}/uploads/#{current_user.email}/#{@file.document.file.filename} #{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}`
        if !ret
          next
        end
        @new_doc = Document.new
        @new_doc.name="#{@sanit_name}.#{ext}"
        @new_doc.user=current_user
        @new_doc.category=@categ
        @new_doc.uploaded_at=@time
        @new_doc.deleted=false
        @new_doc.document.store!(File.open("#{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}"))        
        @new_doc.save!
      end
    end
    #for creating to pdf conversions from .doc and .ppt sox test.mp3 output.raw
    if ['ppt','doc'].include?(@extension.downcase)
        ext='pdf'
        ret=`unoconv -f #{ext} #{Rails.root}/uploads/#{current_user.email}/#{@file.document.file.filename}`
        if !ret
          redirect_to documents_path
          return
        end
        @new_doc = Document.new
        @new_doc.name="#{@sanit_name}.#{ext}"
        @new_doc.user=current_user
        @new_doc.category=@categ
        @new_doc.uploaded_at=@time
        @new_doc.deleted=false
        @new_doc.document.store!(File.open("#{Rails.root}/uploads/#{current_user.email}/#{@file_name}.#{ext}"))        
        @new_doc.save!
    end
    #
    #for creating photo versions PNG only
    if @extension.downcase=='png'
      path="#{Rails.root}/uploads/#{current_user.email}/"
      names=ResamplePng.image_versioning(path,"#{@file.document.file.filename}")
      names.each do |name|
        @new_doc = Document.new
        @new_doc.name=name.gsub(/[0-9]{14}-/,'')
        @new_doc.user=current_user
        @new_doc.category=@categ
        @new_doc.uploaded_at=@time
        @new_doc.deleted=false
        @new_doc.document.store!(File.open("#{Rails.root}/uploads/#{current_user.email}/#{name}"))
        @new_doc.save
      end
    end
    #
    redirect_to documents_path
  end

  def list
    @docs=Document.all
  end

  def download
    if params[:id]!=nil
      @doc=Document.find_by(id: params[:id])
      if @doc!=nil and !@doc.deleted
        @filename=@doc.document.file.filename
        send_file "#{Rails.root}/uploads/#{@doc.user.email}/"<<@filename, :type=>"application/octet-stream"
      else
        if @doc!=nil and current_user.is_sysadmin?
          @filename=@doc.document.file.filename
          send_file "#{Rails.root}/uploads/#{@doc.user.email}/"<<@filename, :type=>"application/octet-stream"
        else
          redirect_to documents_path
        end
      end
    end
  end

  private
  def document_params
    params.require(:document).permit(:description,:document,:remove_document)
  end
end
