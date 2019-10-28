require 'yandex_disk'
require 'rest-client'
require 'json'

# 
# install https://github.com/denwwer/yandex_disk
#

# login yandex disk
yd = YandexDisk.login("arima.yphone", "Yphone8710")
pwd = Dir.pwd
aql = 'items.find({"created":{"$last":"30d"}},{"name":{"$match":"*8710*REL*fastboot*"}},{"repo":{"$eq":"share-yandex"}})'

username = ""
password = ""

def download_cmd(artifactory_file_path, username, password)
  artifactory_url = "http://artifactory.arimacomm.com.tw:8081/artifactory/"
  return "JFROG_CLI_OFFER_CONFIG=false jfrog rt dl --user #{username} --password #{password} --url #{artifactory_url} --split-count 10 #{artifactory_file_path}"
end

def datetime
  return DateTime.now.strftime("%Y-%m-%d %H:%M")
end

while (true) do
  begin
    r = RestClient.post "http://artifactory.arimacomm.com.tw:8081/artifactory/api/search/aql", aql, :content_type => "text/plain"
    r = (JSON.parse(r.to_s))["results"]
    r.each { |result|
      repo = result["repo"]
      path = result["path"]
      name = result["name"]
      properties = RestClient.get "http://artifactory.arimacomm.com.tw:8081/artifactory/api/storage/#{repo}/#{path}/#{name}?properties", :content_type => "application/vnd.org.jfrog.artifactory.storage.ItemProperties+json"
      swversion = (JSON.parse properties.to_s)["properties"]["build.swversion"][0]
      local_path = "#{pwd}/#{path}/#{name}"
      yandex_path = "MMISW/#{swversion}"
      puts "#{swversion}: check image"
      if yd.exist?("#{yandex_path}/#{name}") == false
        #download fastboot images
        system download_cmd("#{repo}/#{path}/#{name}", username, password)
        #upload to yandex disk
        yd.upload("#{local_path}", "#{yandex_path}", { :force => true })
        #remove local file
        system "rm -rf #{pwd}/com"
      end
    }
  rescue
    puts "something wrong there"
  end
  puts datetime + " .. sleep 3600 seconds .."
  puts ""
  sleep 3600
end
