require 'nokogiri'

module Function

  def datetime
    return DateTime.now.strftime("%Y-%m-%d %H:%M")
  end

  def get_filename(file_id)
     i = 0
    while i < 50
      file_name = `gdrive-linux-x64 info #{file_id}`.match(/Name: (.*)/).to_a[1]
      if file_name
        i = 51
      else
        i += 1
      end
    end
    return "#{file_name}"
#    return `gdrive-linux-x64 info #{file_id}`.match(/Name: (.*)/).to_a[1]
  end

  def get_remote_filemd5(file_id)
     i = 0
    while i < 50
      file_md5 = `gdrive-linux-x64 info #{file_id}`.match(/Md5sum: (.*)/).to_a[1]
      if file_md5
        i = 51
      else
        i += 1
      end
    end
    return "#{file_md5}"
#    return `gdrive-linux-x64 info #{file_id}`.match(/Md5sum: (.*)/).to_a[1]
  end

  def get_local_filemd5(dest)
    dest = "#{dest}".gsub('\ ', ' ')
    return `md5sum '#{dest}' `.split('  ')[0]
  end

  def get_fileid(url)
    link = url.split('/')
    link.each {|l|
      if l.length > 25
        return l.gsub('open?id=', "")
      end
    }
  end

end

