require 'chatwork'

ChatWork.api_key = "ae9a324f4cc3cca7a3a4bb1688cf99c3"

module Download

  def download(file_id, dest)
    if(File.exist?("#{dest}")) 
      puts "exist #{dest}"
      dest = dest.gsub(/\s/, '\ ')
      local_file_md5 = get_local_filemd5(dest)
      remote_file_md5 = get_remote_filemd5(file_id)
      if local_file_md5 != remote_file_md5
        puts "#{local_file_md5} != #{remote_file_md5}, delete file"
       #`rm -rf #{dest}`
      else
        puts "#{local_file_md5} == #{remote_file_md5}"
      end
    else
      puts "download > #{dest}"
      @service.get_file(file_id, download_dest: dest)
      tmp = "update #{dest}".gsub!('/home/administrator/server-N', 'N:').gsub('/', '\\').gsub('\ ', ' ')
    end
  end

  def download_folder(file_id, dest)
    FileUtils.mkdir_p "#{dest}"
    Dir.chdir "#{dest}"
    puts "check #{dest}"
    `gdrive-linux-x64 download --recursive #{file_id}`
  end

  def download_by_wget(file_link, dest, file_name)
    if(File.exist?("#{dest}")) 
      puts "exist #{dest}"
    else
      puts "download > #{dest}"
      dest = dest.gsub("#{file_name}", '')
      `wget #{file_link} -P #{dest}`
      dest = "#{dest}#{file_name}"
      tmp = "update #{dest}".gsub!('/home/administrator/server-N', 'N:').gsub('/', '\\').gsub('\ ', ' ')
    end
  end

end

