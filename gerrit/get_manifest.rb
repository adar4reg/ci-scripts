#!/usr/bin/env ruby

require 'rest-client'


host = ENV["host"]
amss_branch = ENV["amss_branch"]
android_branch = ENV["android_branch"]
datetime = ENV["datetime"]
android_file_name = './android/' + datetime + '.xml'
amss_file_name = './amss/' + datetime + '.xml'
datetime = DateTime.strptime("#{datetime}", '%Y%m%d.%H%M%S').strftime("%Y-%m-%d %H:%M:%S")

def encode(string)
  string = string.gsub "/", "%2F"
  string = string.gsub ".", "%2E"
  return string
end

def get_static_manifest(host, manifest_project, branch, datetime, output_file)
  url = "http://#{host}/manifests/static?repository=#{encode(manifest_project)}&branch=#{encode(branch)}&date=#{datetime}"
  manifest = RestClient.get(url)
  file = File.open(output_file, "w")
  file.puts manifest
  file.close
end

Dir.mkdir("android") unless File.exists?("android")
Dir.mkdir("amss") unless File.exists?("amss")

get_static_manifest(host, "platform/manifest", android_branch, datetime, android_file_name)
get_static_manifest(host, "platform/amssmanifest", amss_branch, datetime, amss_file_name)
