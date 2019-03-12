require 'rest-client'
require 'json'
require 'digest'

def download(url, file)
  puts "download #{file} ..."
  result = RestClient.get url
  File.write(file, result.to_s)
end

def upload(url, file)
  puts "upload #{file} ..."
  md5 = Digest::MD5.hexdigest File.read(file)
  RestClient.put url, File.open(file, 'rb'), {"X-Checksum": md5}
end

project = ARGV[0]

base_url = "http://artifactory.arimacomm.com.tw:8081/artifactory"
aql = 'items.find({"$and":[{"created":{"$last":"2days"}},{"name":{"$match":"' + project + '*userdebug*fastbootimage.7z"}}]})'
result = RestClient.post "#{base_url}/api/search/aql", aql, :content_type => "text/plain"
files = JSON.parse(result.to_s)["results"]

files.each do |file|
  begin
    fastboot_artifact = file['name']
    autotest_artifact = fastboot_artifact.sub('fastbootimage.7z', 'autotest.zip')
    RestClient.get "#{base_url}/api/storage/libs-test-local/#{file['path']}/#{autotest_artifact}"
  rescue    
    download("#{base_url}/#{file['repo']}/#{file['path']}/#{fastboot_artifact}", fastboot_artifact)

    system("./tradefed.sh", "#{project}", "#{fastboot_artifact}", "#{autotest_artifact}")

    if $?.exitstatus > 0
      exit($?.exitstatus)
    end
    
    upload("#{base_url}/libs-test-local/#{file['path']}/#{autotest_artifact}", autotest_artifact)
  end
end
