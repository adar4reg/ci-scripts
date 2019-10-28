require_relative 'authorize'
require_relative 'download'
require_relative 'function'
require 'rest-client'

class Synchronizer

  include Authorize
  include Download
  include Function

  def wget_pages
    `wget -x -q --load-cookies ~/bin/cookies.txt https://support.google.com/androidpartners_gms/answer/6173316 -O ./pages/gms.html`
    `wget -x -q --load-cookies ~/bin/cookies.txt https://support.google.com/androidpartners_gms/answer/9124364 -O ./pages/gts.html`
    `wget -x -q --load-cookies ~/bin/cookies.txt https://support.google.com/androidpartners_gms/answer/9124917 -O ./pages/vts.html`
    `wget -x -q --load-cookies ~/bin/cookies.txt https://source.android.com/compatibility/cts/downloads -O ./pages/cts.html`
  end

  def gms
    puts "check lastest GMS"
    page = Nokogiri::HTML(open("/media/d/workspace/06.gms_gts_cts/pages/gms.html"))
    table = page.xpath("//table/tbody/tr/td/p/a[@target='_blank'][@rel='noopener']","//table/tbody/tr/td/ul/li/a[@target='_blank'][@rel='noopener']")
    platform_versions = ['9.0', '8.1', '8.0']
    target_path = "/home/administrator/server-N/SWLibrary/windRiver/GMS"
    table.each {|r|
      file_type = r.text
      file_link = r.xpath('@href').text
      file_id = get_fileid(file_link)
      file_name = get_filename(file_id)
      platform_versions.each{ |platform_version|
        if platform_version == "9.0"
          platform_version = "9"
        end
        if not file_name.nil?
          if file_name.include? "-#{platform_version}-"
            if platform_version == "9"
              platform_version = "9.0"
            end
            dest = "#{target_path}/Android #{platform_version}/#{file_name}"
            download(file_id, dest)
          end
          if file_name.include? "Release"
            if file_name.include? "#{platform_version}"
              if platform_version == "9"
                platform_version = "9.0"
              end
              dest = "#{target_path}/Android #{platform_version}/#{file_name}"
              download(file_id, dest)
            end
          end
        end
      }
    }
  end

  def gts
    puts "check lastest GTS"
    page = Nokogiri::HTML(open("/media/d/workspace/06.gms_gts_cts/pages/gts.html"))
    table = page.xpath("//table/tbody/tr/td/a[@target='_blank'][@rel='noopener']", "//table/tbody/tr/td/p/a[@target='_blank'][@rel='noopener']")
    target_path = "/home/administrator/server-N/SWLibrary/windRiver/GTS"

    table.each {|f|
      file_link = f.xpath('@href').text
      link = file_link.split('/')
      link.each {|l|
        if l.length > 25
          file_id = l.gsub('open?id=', "")
          file_name = get_filename("#{file_id}")
          if not file_name.nil?
            dest = "#{target_path}/#{file_name}"
            download(file_id, dest)
          end
        end
      }
    }
  end

  def vts
    puts "check lastest VTS"
    page = Nokogiri::HTML(open("/media/d/workspace/06.gms_gts_cts/pages/vts.html"))
    table = page.xpath("//table/tbody/tr/td/ul/li/a")
    platform_versions = ['9.0', '8.1', '8.0']
    target_path = "/home/administrator/server-N/SWLibrary/windRiver/VTS_and_GSIs"

    table.each {|f|
      file_type = f.text
      file_link = f.xpath('@href').text
      if not file_type.nil?
        if file_type.include? "arm"
          platform_versions.each{ |platform_version|
            if platform_version == "9.0"
              platform_version = "9"
            end
            if file_type.include? "VTS-#{platform_version}"
              file_id = get_fileid(file_link)
              file_name = get_filename(file_id)
              if not file_name.nil?
                if platform_version == "9"
                  platform_version = "9.0"
                end
                dest = "#{target_path}/Android #{platform_version}/#{file_type}-#{file_name}"
                download(file_id, dest)
              end
            end
          }
        end
      end
    }
  end

  def gsi
    puts "check lastest GSIs"
    page = Nokogiri::HTML(open("/media/d/workspace/06.gms_gts_cts/pages/vts.html"))
    table = page.xpath("//table/tbody/tr/td/ul/li/a")
    platform_versions = ['9.0', '8.1', '8.0']
    target_path = "/home/administrator/server-N/SWLibrary/windRiver/VTS_and_GSIs"
    pwd = Dir.pwd
    table.each {|f|
      file_type = f.text
      file_link = f.xpath('@href').text
      if not file_type.nil?
        if file_type.include? "arm64_ab"
          platform_versions.each{ |platform_version|
            if platform_version == "9.0"
              platform_version = "9"
            end
            if file_type.include? "#{platform_version}_r"
              file_id = get_fileid(file_link)
              if platform_version == "9"
                platform_version = "9.0"
              end
              dest = "#{target_path}/Android #{platform_version}/#{file_type}"
              download_folder(file_id, dest)
           end
          }
        end
        if file_type.include? "arm_a"
          if !file_type.include? "arm_ab"
            if file_type.include? "8.1_r"
              file_id = get_fileid(file_link)
              dest = "#{target_path}/Android 8.1/#{file_type}"
              download_folder(file_id, dest)
            end
          end
        end
        if file_type.include? "arm64_a"
          if !file_type.include? "arm64_ab"
            if file_type.include? "9_r"
              file_id = get_fileid(file_link)
              dest = "#{target_path}/Android 9.0/#{file_type}"
              download_folder(file_id, dest)
            end
          end
        end
      end
    }
    Dir.chdir "#{pwd}"
  end

  def cts
    puts "check lastest CTS"
    page = Nokogiri::HTML(open("/media/d/workspace/06.gms_gts_cts/pages/cts.html"))
    all_file_link = page.xpath('//@href')
    platform_versions = ['9.0', '8.1', '8.0', '7.1', '7.0']
    target_path = "/home/administrator/server-N/SWLibrary/windRiver/CTS"
    
    all_file_link.each {|file_link|
      file_link = file_link.text
      file_name = file_link.split('/')[-1]
      dest = "#{target_path}/#{file_name}"
      if not file_name.nil?
        if file_name.include? "arm"
          platform_versions.each{ |platform_version|
            if file_name.include? "android-cts-#{platform_version}"
              download_by_wget(file_link,dest,file_name)
            end
            if file_name.include? "android-cts-verifier-#{platform_version}"
              download_by_wget(file_link,dest,file_name)
            end
          }
        end
        if file_name.include? "android-cts-media"
          download_by_wget(file_link,dest,file_name)
        end
      end
    }
  end

end
