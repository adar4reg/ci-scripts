require 'rest-client'
require 'json'
require 'digest'

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
    puts "download #{fastboot_artifact} ..."
    result = RestClient.get "#{base_url}/#{file['repo']}/#{file['path']}/#{fastboot_artifact}"
    File.write(fastboot_artifact, result.to_s)

    system("./tradefed.sh", "#{project}", "#{fastboot_artifact}", "#{autotest_artifact}")
    
    if $?.exitstatus > 0
      exit($?.exitstatus)
    end

    puts "upload #{autotest_artifact} ..."
    md5 = Digest::MD5.hexdigest File.read(autotest_artifact)
    RestClient.put "#{base_url}/libs-test-local/#{file['path']}/#{autotest_artifact}", File.open(autotest_artifact, 'rb'), {"X-Checksum": md5}
  end
end
