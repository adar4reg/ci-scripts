require 'json'
require 'optimist'
require 'rest-client'

options = Optimist::options do
  opt :project, 'Require the project for query artifactory files', :type => :string, :required => true
  opt :timestamp, 'Require the timestamp for query artifactory files', :type => :string, :required => true
  opt :username, 'Require the username for query artifactory files', :type => :string, :required => true
  opt :password, 'Require the password for query artifactory files', :type => :string, :required => true
  opt :srcRepoKey, 'Require repository name which had been copied from', :type => :string, :default => 'libs-staging-local', :required => true
  opt :dstRepoKey, 'Require repository name which had been copied to', :type => :string, :required => true
  opt :filetype, 'Require the filetype for query artifactory files', :type => :string, :required => true
  opt :dryrun, 'Require dry-run for this build', :type => :string, :default => '1', :required => true
end

puts options

options[:filetype] = 'all' if options[:dstRepoKey] == 'libs-release-local'
options[:filetype] = options[:filetype] == 'all' ? '' : (options[:filetype] + '*')
query_name = "#{options[:project]}*#{options[:timestamp]}*#{options[:filetype]}"

query = {
  '$and': [
    {'repo': {'$eq': options[:srcRepoKey]}},
    {'name': {'$match': query_name}}
  ]
}

puts JSON[query]
query = "items.find(#{JSON[query]})"


def copy_file(src_file, dest_file, dryrun, api_base)
  RestClient.post "#{api_base}/copy/#{src_file}?to=/#{dest_file}&dry=#{dryrun}",
      {produces: 'application/vnd.org.jfrog.artifactory.storage.CopyOrMoveResult+json'}
end


### query file
api_base = "http://#{options[:username]}:#{options[:password]}@artifactory.arimacomm.com.tw:8081/artifactory/api"
results = RestClient.post "#{api_base}/search/aql", query, {content_type: 'text/plain'}
(JSON.parse results.to_s)["results"].each { |result|
  repo = result['repo']
  path = result['path']
  name = result['name']
  src_file = "#{repo}/#{path}/#{name}"
  dest_file = "#{options[:dstRepoKey]}/#{path}/#{name}"

  puts copy_file("#{src_file}", "#{dest_file}", "#{options[:dryrun]}", "#{api_base}")
}
