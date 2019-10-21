require 'json'
require 'optparse'
require 'rest-client'

options = {}
option_parser = OptionParser.new do |parser|
  parser.on("-p PROJECT", "--project=p", /\A[^\-]+/, "Require the project for query artifactory files") do |project|
    options[:project] = project
  end
  parser.on("-t TIMESTAMP", "--timestamp=t", /\A[^\-]+/, "Require the timestamp for query artifactory files") do |timestamp|
    options[:timestamp] = timestamp
  end
  parser.on("-u USERNAME", "--username=u", /\A[^\-]+/, "Require the username for query artifactory files") do |username|
    options[:username] = username
  end
  parser.on("-w PASSWORD", "--password=w", /\A[^\-]+/, "Require the password for query artifactory files") do |password|
    options[:password] = password
  end
  parser.on("-s SOURCEREPO", "--srcRepoKey=c", /\A[^\-].*/, "Require repository name which had been copied from") do |srcRepoKey|
    options[:srcRepoKey] = srcRepoKey
  end
  parser.on("-c DESTINATIONREPO", "--dstRepoKey=c", /\A[^\-].*/, "Require repository name which had been copied to") do |dstRepoKey|
    options[:dstRepoKey] = dstRepoKey
  end
  parser.on("-f FILETYPE", "--filetype=f", /\A[^\-]+/, "Require the filetype for query artifactory files") do |filetype|
    options[:filetype] = filetype
  end
  parser.on("-d DRYRUN", "--dryrun=c", /\A[^\-]+/, "Require dry-run for this build") do |dryrun|
    options[:dryrun] = dryrun
  end
end


begin
  ARGV << "-h" if ARGV.size < 1
  option_parser.parse!(ARGV)
  raise OptionParser::MissingArgument if options[:project].nil? or options[:timestamp].nil? or options[:username].nil? or options[:password].nil? or options[:dstRepoKey].nil?
  options[:filetype] = "fastboot" if options[:filetype].nil?
  options[:dryrun] = "1" if options[:dryrun].nil?
rescue OptionParser::ParseError
  if $!.to_s =~ /invalid\s+argument\:\s+(\-\S+)\s+\-/ or $!.to_s =~ /missing argument/
    $stderr.print "Error: missing argument value: #{$1}\n"
  else
    $stderr.print "Error: " + $!.to_s + "\n"
  end
  puts "#{option_parser}"
  exit
end

puts "project: #{options[:project]}, timestamp: #{options[:timestamp]},srcRepoKey: #{options[:srcRepoKey]}, dstRepoKey: #{options[:dstRepoKey]}"
puts "filetype: #{options[:filetype]}, dryrun: #{options[:dryrun]}"

project = options[:project]
timestamp = options[:timestamp]
username = options[:username]
password = options[:password]
srcRepoKey = options[:srcRepoKey]
dstRepoKey = options[:dstRepoKey]
filetype = options[:filetype]
dryrun = options[:dryrun]
query_type = "name"
query_name = "#{project}*#{timestamp}*"
query_operation = "or"

filetype = "all" if dstRepoKey == "libs-release-local"

if filetype == "all"
  filetype = ""
else
  filetype = filetype + "*"
end

query = "items.find({
  \"$and\":
  [
    {\"repo\":{\"$eq\":\"#{srcRepoKey}\"}},
    {\"$#{query_operation}\":[
      {\"#{query_type}\" : {\"$match\" : \"#{query_name}#{filetype}\"}}
    ]}
  ]
})"

def copy_file(src_file, dest_file, dryrun, username, password)
  RestClient.post "http://#{username}:#{password}@artifactory.arimacomm.com.tw:8081/artifactory/api/copy/#{src_file}?to=/#{dest_file}&dry=#{dryrun}", {produces: "application/vnd.org.jfrog.artifactory.storage.CopyOrMoveResult+json"}
end


### query file
results = RestClient.post "http://#{username}:#{password}@artifactory.arimacomm.com.tw:8081/artifactory/api/search/aql", query, {content_type: "text/plain"}
(JSON.parse results.to_s)["results"].each { |result|
  repo = result["repo"]
  path = result["path"]
  name = result["name"]
  src_file = "#{repo}/#{path}/#{name}"
  dest_file = "#{dstRepoKey}/#{path}/#{name}"
  puts "src_file  : #{src_file}\ndest_file : #{dest_file}"
  puts copy_file("#{src_file}", "#{dest_file}", "#{dryrun}", "#{username}", "#{password}")
}
