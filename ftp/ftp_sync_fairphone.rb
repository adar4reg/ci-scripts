require 'net/sftp'
require 'net/ssh/proxy/http'
require 'rest-client'
require 'json'

# use sftp
# sync local folder /media/d/workspace/tmp2/com/arimacomm/8901/ to /FP3_Releases/
#

proxy = Net::SSH::Proxy::HTTP.new('aptcacher.arimacomm.com.tw', 3142)
sftp = Net::SFTP.start('fptpe.synology.me', 'yw.peng', password: 'vc?XZE', proxy: proxy)

server = "artifactory.arimacomm.com.tw"
to = "/media/d/workspace/tmp2"
aql = 'items.find({"repo":{"$eq":"share-fairphone"}})'

def datetime
  return DateTime.now.strftime("%Y-%m-%d %H:%M")
end

def self.get_md5(server, repo, path, name)
  r = RestClient.get "http://#{server}:8081/artifactory/api/storage/#{repo}/#{path}/#{name}"
  r= JSON.parse(r.to_s)
  return r["checksums"]["md5"]
end

def self.checkmd5(local_file, md5)
  local_md5 = `md5sum #{local_file}`
  local_md5 = local_md5.split(' ')[0]
  if local_md5 == md5
    fh = File.open("#{local_file}.md5", "w")
    fh.puts md5
    fh.close
  else
    system("rm -rf #{full_path}")
  end
end

while (true) do
  begin
    system('rm -rf /media/d/workspace/tmp2/com/arimacomm/8901')
    r = RestClient.post "http://#{server}:8081/artifactory/api/search/aql", aql, :content_type => "text/plain"
    r = (JSON.parse(r.to_s))["results"]
    r.each { |result|
      repo = result["repo"]
      path = result["path"]
      name = result["name"]
      md5 = get_md5(server, repo, path, name)
      folderName = path.split("/")[-1]
      localPath = "/media/d/workspace/tmp2/" + path
      localFile = localPath + "/" + name
      remotePath = "/FP3_Releases/" + folderName
      remoteFile = remotePath + "/" + name
      begin
        sftp.stat! remoteFile
      rescue Net::SFTP::StatusException => e
        if e.code == 2
          uri = "http://#{server}:8081/artifactory/#{repo}/#{path}/#{name}"
          r = RestClient.get uri
          if !Dir.exist?("#{to}/#{path}")
            FileUtils.mkdir_p("#{to}/#{path}")
          end
          file = File.new("#{to}/#{path}/#{name}", "w")
          file.write(r.to_s)
          file.close
          checkmd5(localFile, md5)
          localMd5file = localFile + ".md5"
          remoteMd5file = remoteFile + ".md5"
          puts "upload #{remoteFile}"
          begin
            sftp.mkdir! remotePath
          rescue Net::SFTP::StatusException => e
            #folder exist, carry on
          end
          sftp.upload!(localFile, remoteFile)
          sftp.upload!(localMd5file, remoteMd5file)
        end
      end
    }
  rescue
    puts "something wrong there"
  end
  puts datetime + " .. sleep 300 seconds .."
  puts ""
  sleep 300
end
