class DocumentsController < ApplicationController
  layout 'standard'
  require 'document_aux'
  require 'resample_png'
  before_action :authenticate_user!

  def new
    @file = Document.new
    if current_user.is_sysadmin?
      if (params[:categ] && params[:categ] != '-1')
        @docs = Document.where("category_id = #{params[:categ]}")
        return
      end
      @docs = Document.all
      return
    end
    if current_user.is_admin?
      if (params[:categ] && params[:categ] != '-1')
        @docs = Document.where("category_id = #{params[:categ]} and deleted = false")
        return
      end
      @docs = Document.where("deleted = false")
      return
    end
    if (params[:categ] == '-1' || !params[:categ])
      @docs = Document.joins(:category).where("deleted = false and original = true and categories.approved = true")
      return
    else
      @docs = Document.joins(:category).where("category_id = '#{params[:categ]}' and deleted = false and original = true and categories.approved = true")
      return
    end
  end

  def change_state
    if (params[:id] && (current_user.is_sysadmin? || current_user.is_admin?))
      @doc = Document.find_by(id: params[:id])
      if @doc
        if @doc.deleted
          flash[:notice] = "File succesfully recovered!"
        else
          flash[:notice] = "File succesfully deleted!"
        end
        @doc.deleted = !@doc.deleted
        @doc.save
      else
        flash[:alert] = "Attempting to delete invalid file!"
      end
    else
      flash[:alert] = "Invalid acces or file!"
    end
    redirect_to documents_path
  end

  def force_delete
    if (!params[:id] || !current_user.is_sysadmin?)
      flash[:alert] = "Invalid user or file!"
      redirect_to documents_path
      return
    end
    @doc = Document.find_by(id: params[:id])
    if @doc
      if @doc.original
        @doc.get_versions.each do |version|
          version.remove_document
          version.destroy
        end
      end
      @doc.remove_document
      @doc.destroy
    else
      flash[:alert] = "No file found!"
      redirect_to documents_path
      return
    end
    flash[:notice] = "File succesfully deleted(permanently)!"
    redirect_to documents_path
  end

  def create
    @file = Document.new(document_params)

    if !@file.document.file
      flash[:alert] = "Invalid upload! No file given!"
      redirect_to documents_path
      return
    end

    @time = Time.now
    @categ = Category.find_by(id: params[:category][:id])
    @name = params[:document][:document].original_filename.gsub(/\.(.*)/,'')
    @sanit_name = DocumentAux::sanitize(@name)
    @path = "#{Rails.root}/uploads/#{current_user.email}"
    
    @file.original = true
    @file.user = current_user
    @file.uploaded_at = @time
    @file.deleted = false
    @file.name = @file.document.file.filename
    @file.category = @categ
    @file.save
    @file_name = @file.document.file.filename.gsub(/\.(.*)/,'')
    #for creating conversions
    @extension = @file.document.file.extension

    if ['xls','csv','ots','ods'].include?(@extension.downcase)
      ['xls','csv','ots','ods','pdf'].each do |ext|
        if ext == @extension
          next
        end

        ret = `unoconv -f #{ext} #{@path}/#{@file.document.file.filename}`

        if !ret
          flash[:alert] = "File uploaded but some conversions failed!"
          next
        else
          store_file("#{@sanit_name}.#{ext}","#{@file_name}.#{ext}", @path, @categ, @time, false)
        end
      end

    end

    #for creating file conversion for video formats
    if ['mp4','avi','mpeg','mkv'].include?(@extension.downcase)
      ['mp4','avi','mpeg','mkv'].each do |ext|

        if ext == @extension
          next
        end

        ret = `ffmpeg -i #{@path}/#{@file.document.file.filename} -strict -2 #{@path}/#{@file_name}.#{ext}`

        if !ret
          flash[:alert] = "File uploaded but some conversions failed!"
          next
        else
          store_file("#{@sanit_name}.#{ext}","#{@file_name}.#{ext}", @path, @categ, @time, false)
        end        
      end

    end

    #for creating file conversion for audio formats
    if ['mp3','wav','ogg','flac'].include?(@extension.downcase)
      ['mp3','wav','ogg','flac'].each do |ext|

        if ext == @extension
          next
        end

        ret = `sox #{@path}/#{@file.document.file.filename} #{@path}/#{@file_name}.#{ext}`

        if !ret
          flash[:alert] = "File uploaded but some conversions failed!"
          next
        else
          store_file("#{@sanit_name}.#{ext}","#{@file_name}.#{ext}", @path, @categ, @time, false)
        end
      end

    end

    #for creating to pdf conversions from .doc and .ppt sox test.mp3 output.raw
    if ['ppt','doc'].include?(@extension.downcase)
      ext = 'pdf'
      ret = `unoconv -f #{ext} #{@path}/#{@file.document.file.filename}`

      if !ret
        redirect_to documents_path
        flash[:alert] = "File uploaded but the conversion failed!"
        return
      end

      store_file("#{@sanit_name}.#{ext}","#{@file_name}.#{ext}", @path, @categ, @time, false)
    end
    #
    #for creating photo versions PNG only
    if @extension.downcase == 'png'
      names = ResamplePng.image_versioning(path,"#{@file.document.file.filename}")
      names.each do |name|
        store_file("#{name.gsub(/[0-9]{14}-/,'')}","#{name}", @path, @categ, @time, false)
      end

    end

    if !flash[:alert]
      flash[:notice] = "File succesfully uploaded and converted!"
    end

    redirect_to documents_path
  end

  def download
    if params[:id]
      @doc = Document.find_by(id: params[:id])
      if (@doc && !@doc.deleted)
        @filename = @doc.document.file.filename
        send_file "#{Rails.root}/uploads/#{@doc.user.email}/"<<@filename, :type => "application/octet-stream"
      else
        if (@doc && current_user.is_sysadmin?)
          @filename = @doc.document.file.filename
          send_file "#{Rails.root}/uploads/#{@doc.user.email}/"<<@filename, :type => "application/octet-stream"
        else
          redirect_to documents_path
        end
      end
    end
  end

  private
  def store_file(name,filename, path, categ, time, original)
    new_doc = Document.new
    new_doc.name = name
    new_doc.user = current_user
    new_doc.category = categ
    new_doc.uploaded_at = time
    new_doc.deleted = false
    new_doc.original = original
    new_doc.document.store!(File.open("#{path}/#{filename}"))
    new_doc.save
  end  

  def document_params
    params.require(:document).permit(:description,:document,:remove_document)
  end
end
