require 'rest-client'
require 'json'

class ArtifactoryReplication

  @@logger

  def self.my_search_by_checksum(from, to, md5)
    results = Array.new
    begin
      r = RestClient.get "http://#{from}:8081/artifactory/api/search/checksum?md5=#{md5}"
      r = JSON.parse(r.to_s)
      r = r["results"]
      r.each { |result|
        uri = result["uri"]
        uri.gsub!("http://#{from}:8081/artifactory/api/storage/", "")
        repo = uri[0..uri.index("/")-1]
        path = uri[uri.index("/")+1..uri.rindex("/")-1]
        name = uri[uri.rindex("/")+1..-1]
        if path_exist?(to, repo, path, name) && md5 == get_md5(to, repo, path, name)
          results << uri
        end
      }
    rescue RestClient::Exception => e
      if e.http_code != 400
        raise
      end
    end
    return results
  end

  def self.get_md5(server, repo, path, name)
    r = RestClient.get "http://#{server}:8081/artifactory/api/storage/#{repo}/#{path}/#{name}"
    r= JSON.parse(r.to_s)
    return r["checksums"]["md5"]
  end

  def self.path_exist?(server, repo, path, name)
    begin
      RestClient.get "http://#{server}:8081/artifactory/api/storage/#{repo}/#{path}/#{name}"
    rescue
      return false
    end
    return true
  end

  def self.sync(from, to, repo, path, name)
    md5 = get_md5(from, repo, path, name)
    results = my_search_by_checksum(from, to, md5)
    uri = results.size > 0? "http://#{to}:8081/artifactory/#{results[0]}" : "http://#{from}:8081/artifactory/#{repo}/#{path}/#{name}"
    @@logger.info "#{repo}/#{path}/#{name}"
    @@logger.info "\tdownload from #{results.size > 0? to : from} ...."
    start_time = Time.now
    r = RestClient.get uri
    file = Tempfile.new(name)
    file.write(r.to_s)
    file.close
    @@logger.info "\tdownload took #{'%.2f' % (Time.now - start_time)}s at #{'%.2f' % (file.size / 1024.0 / 1024.0 / (Time.now - start_time))} MB/s"
    @@logger.info "\tupload to #{to} ...."
    start_time = Time.now
    RestClient.put "http://#{to}:8081/artifactory/#{repo}/#{path}/#{name}", File.open(file.path, 'rb'), {"X-Checksum": md5}
    @@logger.info "\tupload took #{'%.2f' % (Time.now - start_time)}s at #{'%.2f' % (file.size / 1024.0 / 1024.0 / (Time.now - start_time))} MB/s"
  end

  def self.replicate(aql, from, to)
    begin
      r = RestClient.post "http://#{from}:8081/artifactory/api/search/aql", aql, :content_type => "text/plain"
      r = (JSON.parse(r.to_s))["results"]
      r.each { |result|
        repo = result["repo"]
        path = result["path"]
        name = result["name"]
        puts "check #{repo} #{name}"
        if !path_exist?(to, repo, path, name)
#          puts name
          sync(from, to, repo, path, name)
        end
      }
    rescue Exception => e
      @@logger.error e.message
      @@logger.error e.backtrace
    end
  end
end
