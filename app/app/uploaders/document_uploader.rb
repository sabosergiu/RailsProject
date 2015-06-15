class DocumentUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  storage :file

  def extension_white_list
    %w(xls csv ods ots pdf ppt doc avi mkv mpeg mp4 mp3 wav ogg flac png)
  end

  def filename
    if original_filename.present? and super.present? and super.match(/[0-9]{14}-/)
      return super
    end
    @name ||= "#{timestamp}-#{super}" if original_filename.present? and super.present?
  end
  
  def timestamp
    var = :"@#{mounted_as}_timestamp"
    model.instance_variable_get(var) or model.instance_variable_set(var, Time.now.to_s.gsub(/[- :]|\+(.*)/,''))
  end

  def store_dir
    "#{Rails.root}/uploads/#{model.user.email}/"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end


end
