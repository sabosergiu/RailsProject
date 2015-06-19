module Backup
  require 'zip'

  def self.backup
    time=Time.now
    time_str=time.to_s.gsub(/[- :]|\+(.*)/,'')
    archive=BackupArchive.new
    archive.filename="#{time_str}.zip"
    archive.saved_at=time
    archive.save
    create_XML("#{Rails.root}/uploads/index.xml")
    zip=ZipFileGenerator.new("#{Rails.root}/uploads","#{Rails.root}/backups/#{time_str}.zip")
    zip.write
    File.delete("#{Rails.root}/uploads/index.xml")
  end

  def self.create_XML(filename)
    builder=Nokogiri::XML::Builder.new do |xml|
    xml.back_up{
      xml.categories{
      (Category.all).each do |categ|
        xml.category{
          xml.id_ categ.id
          xml.name categ.name
          xml.approved categ.approved
        }
      end
      }
      xml.users{
        User.all.each do |user|
        xml.user{
          xml.id_ user.id
          xml.email user.email
          xml.encrypted_password user.encrypted_password
          xml.username user.username
          xml.password user.password
          xml.user_type user.user_type
          xml.signin_count user.sign_in_count
          xml.last_ip user.last_sign_in_ip
          xml.last_sign_in user.last_sign_in_at
        }
        end
      }
      xml.documents{
        Document.all.each do |doc|
        xml.document{
          xml.id_ doc.id
          xml.name doc.name
          xml.description doc.description
          xml.document doc.document.file.filename
          xml.category_id doc.category_id
          xml.deleted doc.deleted
          xml.user_id doc.user.id
          xml.uploaded_at doc.uploaded_at
          xml.original doc.original
          xml.archive_path "#{doc.user.email}/#{doc.document.file.filename}"
        }
        end
      }
    }
    File.write(filename, xml.to_xml)
    end
  end

  class ZipFileGenerator
    def initialize(inputDir, outputFile)
      @inputDir = inputDir
      @outputFile = outputFile
    end

    def write()
      entries = Dir.entries(@inputDir); entries.delete("."); entries.delete("..")
      io = Zip::File.open(@outputFile, Zip::File::CREATE);
      writeEntries(entries, "", io)
      io.close();
    end

    private
    def writeEntries(entries, path, io)
      entries.each { |e|
        zipFilePath = path == "" ? e : File.join(path, e)
        diskFilePath = File.join(@inputDir, zipFilePath)
        if  File.directory?(diskFilePath)
          io.mkdir(zipFilePath)
          subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
          writeEntries(subdir, zipFilePath, io)
        else
          io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
        end
      }
    end
  end
end
