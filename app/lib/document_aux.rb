module DocumentAux
  def DocumentAux.sanitize(name)
    name = name.gsub("\\", "/")
    name = File.basename(name)
    name = name.gsub(CarrierWave::SanitizedFile.sanitize_regexp,"_")
    name = "_#{name}" if name =~ /\A\.+\z/
    name = "unnamed" if name.size == 0
    return name.mb_chars.to_s
  end
end
