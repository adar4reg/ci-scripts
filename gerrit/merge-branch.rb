#!/usr/bin/env ruby

require 'rest-client'
require 'base64'
require 'nokogiri'
require 'json'
require 'logger'

class MyMergeableInfo
  attr_accessor :project_name
  attr_accessor :project_path
  attr_accessor :mergeable_info
  attr_accessor :source_revision_sha1
  attr_accessor :target_revision_sha1

  def initialize(project_name, project_path, mergeable_info, source_revision_sha1, target_revision_sha1)
    @project_name = project_name
    @project_path = project_path
    @mergeable_info = mergeable_info
    @source_revision_sha1 = source_revision_sha1
    @target_revision_sha1 = target_revision_sha1
  end
end

class Manifest
  attr_accessor :default_revision

  def initialize(manifest)
    @manifest = manifest
    @default_revision = manifest.xpath("//default")[0]["revision"]
  end

  def projects
    @manifest.xpath("//project[not(contains(@groups,'notdefault'))]")
  end

  def find_project(project_name)
    projects = @manifest.xpath("//project[@name='#{project_name}']")
    if projects.nil?
      nil
    else
      projects[0]
    end
  end

  def get_project_revision(project)
    project["revision"].nil? ? @default_revision : project["revision"]
  end

  def get_project_path(project)
    project["path"].nil? ? project["name"] : project["path"]
  end
end

class Gerrit
  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
  end

  def manifest(manifest_project, branch, manifest_file = "default.xml")
    r = RestClient.get "#{url(@host)}/projects/#{encode(manifest_project)}/branches/#{encode(branch)}/files/#{manifest_file}/content"
    Manifest.new(Nokogiri::XML Base64.decode64(r.to_s))
  end

  def mergeable_info(project_name, branch, source)
    r = RestClient.get "#{url(@host)}/projects/#{encode(project_name)}/branches/#{encode(branch)}/mergeable?source=#{source}"
    JSON.parse r.to_s[5..-1]
  end

  def branch(project_name, branch)
    r = RestClient.get "#{url(@host)}/projects/#{encode(project_name)}/branches/#{encode(branch)}"
    (JSON.parse r.to_s[5..-1])["revision"]
  end

  def encode(string)
    string.gsub "/", "%2F"
  end

  def url(host)
    "http://#{@username}:#{@password}@#{host}:8080/a"
  end
end

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

host = ENV["host"]
manifest_project = ENV["manifest_project"]
source_branch = ENV["source_branch"]
target_branch = ENV["target_branch"]
gerrit = Gerrit.new(host, ENV["username"], ENV["password"])
dry_run = ENV["dry_run"]

logger.info("get #{source_branch} manifest")
source_manifest = gerrit.manifest(manifest_project, source_branch)

logger.info("get #{target_branch} manifest")
target_manifest = gerrit.manifest(manifest_project, target_branch)

merge_needed = Array.new
target_manifest.projects.each do |project|
  project_name = project["name"]
  logger.info("check project: #{project_name}")
  source_project = source_manifest.find_project(project_name)
  if !(source_project.nil?)
    source_revision = source_manifest.get_project_revision(source_project)
    target_revision = target_manifest.get_project_revision(project)
    if target_revision != source_revision
      mergeable_info = gerrit.mergeable_info(project_name, target_branch, source_revision)
      if !(mergeable_info["commit_merged"])
        source_revision_sha1 = gerrit.branch(project_name, source_branch)
        target_revision_sha1 = gerrit.branch(project_name, target_branch)
        project_path = target_manifest.get_project_path(project)
        merge_needed.push MyMergeableInfo.new(project_name, project_path, mergeable_info, source_revision_sha1, target_revision_sha1)
      end
    end
  end
end

merge_conflict = merge_needed.select {|my_mergeable_info|
  !(my_mergeable_info.mergeable_info["mergeable"])
}

merge_auto = merge_needed.select {|my_mergeable_info|
  my_mergeable_info.mergeable_info["mergeable"]
}

if merge_conflict.size != 0
  logger.warn("====================================================")
  logger.warn("the following project(s) need to be merged manually:")
  logger.warn("====================================================")
  merge_conflict.each {|my_mergeable_info|
    logger.warn("#{my_mergeable_info.project_name}:")
    logger.warn("\t#{my_mergeable_info.source_revision_sha1} -> #{my_mergeable_info.target_revision_sha1}")
  }
  exit(1)
elsif merge_auto.size == 0
  logger.warn("====================================================")
  logger.warn("no project need to be merged")
  logger.warn("====================================================")
  exit(0)
else
  logger.info("merge #{source_branch} into #{target_branch}")
  `repo init -q -u git://#{host}/#{manifest_project} -b #{target_branch} --reference=/media/d/mirror`
  merge_auto.each {|my_mergeable_info|
    logger.info("#{my_mergeable_info.project_name}:")
    logger.info("\t#{my_mergeable_info.source_revision_sha1} -> #{my_mergeable_info.target_revision_sha1}")
    `repo sync -c #{my_mergeable_info.project_name}`
    Dir.chdir(my_mergeable_info.project_path) do
      `git checkout #{my_mergeable_info.target_revision_sha1}`
      `git fetch origin #{my_mergeable_info.source_revision_sha1}`
      `git config user.name ${GIT_SSH_USER}`
      `git config user.email $(ssh -p 29418 ${GIT_SSH_USER}@#{host} user email)`
      `git merge FETCH_HEAD --no-ff --log -m "Merge branch #{(source_branch.split('-'))[-1]} into #{(target_branch.split('-'))[-1]}"`
    end
  }
  if dry_run != "true"
    merge_auto.each {|my_mergeable_info|
      Dir.chdir(my_mergeable_info.project_path) do
        `git push origin HEAD:refs/for/#{target_branch}`
        `ssh -p 29418 ${GIT_SSH_USER}@#{host} gerrit review $(git rev-parse HEAD) --code-review +2 --verified +1 --submit`
      end
    }
  end
end