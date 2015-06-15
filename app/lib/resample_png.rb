module ResamplePng
  
  require 'chunky_png'
  
  def self.nearest_neighbor (image,new_width,new_height)
    #image = ChunkyPNG::Image.from_file(fname)
    new_image = ChunkyPNG::Image.new(new_width, new_height, ChunkyPNG::Color::TRANSPARENT, image.metadata)
    x_rat,y_rat=resample_ratio(image.width, image.height, new_width, new_height)
    for i in 0...new_image.height#image[#column,line]
      for j in 0...new_image.width
        px=(j*x_rat).floor
        py=(i*y_rat).floor
        new_image[j,i]=image[px,py]
      end
    end
    new_image
  end

  def self.create_version (image, path, fname,width, height)
    case width
    when 11..100
      s1="00#{width}"
    when 101..1000
      s1="0#{width}"
    when 1001..10000
      s1="#{width}"
    end
    case height
    when 11..100
      s2="00#{height}"
    when 101..1000
      s2="0#{height}"
    when 1001..10000
      s2="#{height}"
    end
    str="#{fname.gsub(/\.(.*)/,'')}_#{s1}x#{s2}.png"
    image=nearest_neighbor(image,width,height)
    image.save("#{path}#{str}")
    str
  end

  def self.resample_ratio (width, height, new_width, new_height)
    return width.to_f/new_width, height.to_f/new_height
  end

  def self.resize_version_list
    [[50,50],[200,200],[600,600],[1000,1000]]
  end

  def self.image_versioning(path,fname)
    image = ChunkyPNG::Image.from_file("#{path}#{fname}")
    names=[]
    resize_version_list.each do |dim|
      if image.width<dim[0] or image.height<dim[1]
        break
      end
      names.push(create_version(image,path,fname,dim[0],dim[1]))
    end
    names
  end
end
