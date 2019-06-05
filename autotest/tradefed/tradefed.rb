require 'digest'
require 'json'
require 'optparse'
require 'rest-client'

def download(url, file)
  puts "download #{file} ..."
  result = RestClient.get url
  File.write(file, result.to_s)
end

def upload(url, file)
  puts "upload #{url} ..."
  md5 = Digest::MD5.hexdigest File.read(file)
  RestClient.put url, File.open(file, 'rb'), {"X-Checksum": md5}
end

def run_tradefed(project, serial, fastboot_artifact, autotest_artifact, flasher, testcase)
  system("./tradefed.sh", "#{project}", "#{serial}", "#{fastboot_artifact}", "#{autotest_artifact}", "#{flasher}", "#{testcase}")
  if $?.exitstatus > 0
    exit($?.exitstatus)
  end
end

def get_times(base_url, file)
  times = 0
  payload = 'items.find({"$and":[{"name":{"$match":"'+file+'"}}]}).include("property.*")'
  prop = RestClient.post "#{base_url}/api/search/aql", payload, :content_type => "text/plain"
  properties = JSON.parse(prop.to_s)["results"][0]["properties"]
  properties.each do |prop|
    if prop["key"].eql? "test.times"
      times = prop["value"].to_i
    end
  end
  return times
end

def update_prop(base_url, resource, times)
  payload = '{"props":{"test.times":"' + times+'"}}'
  RestClient.patch "#{base_url}/api/metadata/#{resource}", payload, :content_type => "application/json"
end

def update_link(base_url, resource, link, times)
  payload = '{"props":{"test.times":"' + times+'","test.link' + times + '":"' + link + '"}}'
  RestClient.patch "#{base_url}/api/metadata/#{resource}", payload, :content_type => "application/json"
end

OptionParser.new do |parser|
  parser.on("-p p", "--project=p", "project name") do |project|
    @project = project
  end
  parser.on("-s s", "--serial=s", "serial number") do |serial|
    @serial = serial
  end
  parser.on("-f f", "--flasher=f", "device flasher") do |flasher|
    @flasher = flasher
  end
  parser.on("-r r", "--resource=r", "image resource") do |resource|
    @resource = resource
  end
  parser.on("-t t", "--testcase=t", "testcase name") do |testcase|
    @testcase = testcase
  end
end.parse!

base_url = "http://artifactory.arimacomm.com.tw:8081/artifactory"

if @resource.nil? || @resource.empty?
  aql = 'items.find({"$and":[{"created":{"$last":"2days"}},{"name":{"$match":"' + @project + '*REL*userdebug*fastbootimage.7z"}}]})'
  result = RestClient.post "#{base_url}/api/search/aql", aql, :content_type => "text/plain"
  files = JSON.parse(result.to_s)["results"]
  files.each do |file|
    # set up variables
    fastboot_artifact = file['name']
    next if get_times(base_url, fastboot_artifact) > 0
    times = (get_times(base_url, fastboot_artifact)+1).to_s
    autotest_artifact = fastboot_artifact.sub('fastbootimage.7z', 'autotest.zip')
    # start testing
    download("#{base_url}/#{file['repo']}/#{file['path']}/#{fastboot_artifact}", fastboot_artifact)
    run_tradefed(@project, @serial, "#{fastboot_artifact}", "#{autotest_artifact}", @flasher, @testcase)
    upload("#{base_url}/#{file['repo']}/#{file['path']}/#{autotest_artifact}", autotest_artifact)
    update_prop(base_url, "#{file['repo']}/#{file['path']}/#{fastboot_artifact}", times)
  end
else
  # set up variables
  path = @resource.rpartition('/').first.rpartition('local/').last
  fastboot_artifact = @resource.rpartition('/').last
  times = (get_times(base_url, fastboot_artifact)+1).to_s
  autotest_artifact = fastboot_artifact.sub('fastbootimage.7z', 'test' + times + '.zip')
  # start testing
  system("ruby", "configuration.rb", @testcase, @project)
  download("#{base_url}/#{@resource}", fastboot_artifact)
  run_tradefed(@project, @serial, "#{fastboot_artifact}", "#{autotest_artifact}", @flasher, "../test.xml")
  upload("#{base_url}/libs-test-local/#{path}/#{autotest_artifact}", autotest_artifact)
  update_link(base_url, @resource, "#{base_url}/libs-test-local/#{path}/#{autotest_artifact}", times)
end
