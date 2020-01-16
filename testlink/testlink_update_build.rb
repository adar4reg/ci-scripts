#!/usr/bin/env ruby

require 'nokogiri'
require 'rest-client'
require 'xmlrpc/client'
require 'json'
require 'date'

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"

def get_projects()
  args = {devKey: @key}
  r = @server.call('tl.getProjects', args)
  r
end

def get_project_test_plans(testprojectid)
  args = {devKey: @key, testprojectid: testprojectid}
  r = @server.call('tl.getProjectTestPlans', args)
  r
end

def create_build(testplanid, buildname, releasedate, buildnotes)
  args = {devKey: @key, testplanid: testplanid, buildname: buildname, releasedate: releasedate, buildnotes: buildnotes}
  r = @server.call('tl.createBuild', args)
  puts r
end

query = "
items.find(
    {\"$and\":[
        {\"created\":{\"$last\":\"1d\"}},
        {\"$or\":[
            {\"repo\":{\"$eq\":\"libs-snapshot-local\"}},
            {\"repo\":{\"$eq\":\"libs-staging-local\"}}
        ]},
        {\"name\" : {\"$match\" : \"**-fastbootimage*7z\"}},
        {\"name\" : {\"$nmatch\" : \"*9970**user-fastbootimage*7z\"}},
        {\"name\" : {\"$nmatch\" : \"*9971**user-fastbootimage*7z\"}}
    ]}
)"

artifactory_server_tp = "artifactory.arimacomm.com.tw"
results = RestClient.post "http://#{artifactory_server_tp}:8081/artifactory/api/search/aql", query, {content_type: "text/plain"}
results = (JSON.parse results.to_s)["results"]

root = Dir.pwd
results.each { |result|
  repo = result["repo"]  #libs-staging-local
  path = result["path"]  #com/arimacomm/6612/6612-MSM8917/20171208.220152-userdebug
  name = result["name"]  #6612-MSM8917-20171208.220152-userdebug-fastbootimage.7z

  if repo == 'libs-staging-local'
    sw_type = "offcail_build"
  elsif name.include?('daily')
    sw_type = "daily_build"
  elsif name.include?('continuous')
    sw_type = "continuous_build"
  end

  begin
    file = repo + "/" + path + "/" + name
    file_Statistics = RestClient.get "http://#{artifactory_server_tp}:8081/artifactory/api/storage/#{file}?properties"
    file_Statistics = (JSON.parse file_Statistics.to_s)

    swversion = file_Statistics["properties"]["build.swversion"][0]
    branch = file_Statistics["properties"]["build.branch"][0]
    timestamp = file_Statistics["properties"]["build.timestamp"][0].to_i
    datetime = (Time.at(timestamp/1000)+0530).strftime("%Y-%m-%d")
    project_artifactary = file_Statistics["properties"]["build.name"][0][0..3]

    projects = get_projects()
    projects.each{ |project|
      project_id = project['id']
      project_id = '9364'
      plans = get_project_test_plans(project_id)
      if plans != '' && swversion != '' && !swversion.include?('-userdebug')
        plans.each{ |plan|
          project_testlink = plan['name'][0..3]
          testplanid = plan['id']
          if project_artifactary == project_testlink
            buildnotes = "#{branch}-#{sw_type}"
            create_build(testplanid, swversion, datetime, buildnotes)
          end
        }
      end
    }
  rescue
  ensure
  end
}
