require 'rest-client'
require 'json'
require 'pathname'
require 'fileutils'

class SyncLocal

  @@logger

  def self.get_md5(server, repo, path, name)
    r = RestClient.get "http://#{server}:8081/artifactory/api/storage/#{repo}/#{path}/#{name}"
    r= JSON.parse(r.to_s)
    return r["checksums"]["md5"]
  end

  def self.path_exist?(folder, path, name)
    return Pathname.new("#{folder}/#{path}/#{name}").exist?
  end

  def self.checkmd5(full_path, md5)
    local_md5 = `md5sum #{full_path}`
    local_md5 = local_md5.split(' ')[0]
    if local_md5 == md5
      fh = File.open("#{full_path}.md5", "w")
      fh.puts md5
      fh.close
    else
      system("rm -rf #{full_path}")
    end
  end

  def self.sync(from, to, repo, path, name)
    md5 = get_md5(from, repo, path, name)
    uri = "http://#{from}:8081/artifactory/#{repo}/#{path}/#{name}"
    @@logger.info "#{repo}/#{path}/#{name}"
    @@logger.info "\tdownload from #{from} ...."
    start_time = Time.now
    r = RestClient.get uri
    if !Dir.exist?("#{to}/#{path}")
      FileUtils.mkdir_p("#{to}/#{path}")
    end
    file = File.new("#{to}/#{path}/#{name}", "w")
    file.write(r.to_s)
    file.close
    full_path = "#{to}/#{path}/#{name}"
    checkmd5(full_path, md5)
  end

  def self.replicate(aql, from, to)
    begin
      r = RestClient.post "http://#{from}:8081/artifactory/api/search/aql", aql, :content_type => "text/plain"
      r = (JSON.parse(r.to_s))["results"]
      r.each { |result|
        repo = result["repo"]
        path = result["path"]
        name = result["name"]
        if !path_exist?(to, path, name)
          puts "downloading #{name}"
          sync(from, to, repo, path, name)
        end
      }
    rescue Exception => e
      @@logger.error e.message
      @@logger.error e.backtrace
    end
  end
end
