#!/usr/bin/env ruby

require 'rest-client'
require 'json'
require 'spreadsheet'
require 'nokogiri'

def encode(string)
  string = string.gsub "/", "%2F"
  string = string.gsub ".", "%2E"
  return string
end

def extract(message, pattern)
  result = []
  matchs = message.scan(/#{pattern}/i)
  if matchs.any?
    matchs.each do |match|
      result << match[0].strip
    end
  end
  return result.join("\n")
end

def set_meta(sheet, sincetime, untiltime, branch)
  sheet[0, 0] = "Branch : #{branch}"
  sheet[1, 0] = "Diff : #{sincetime} <> #{untiltime}"
  table_head = ["Commit", "Commit Date", "Subject", "Committer", "RiskArea", "Fix Issue", "Feature", "Root cause", "How to fix", "Project", "Commit Message", "File List"]
  table_head.each_with_index do |value, index|
    sheet[3, index] = value
  end
end

def get_commits(host, repo_manifest, branch, since_time, until_time)
  r = RestClient.get "http://#{host}/manifests/diff?repository=#{encode(repo_manifest)}&branch=#{encode(branch)}&since=#{since_time}&until=#{until_time}"
  commits = JSON.parse r
  return commits
end

def get_files(host, project, commit)
  url = "http://#{host}/projects/#{encode(project)}/commits/#{commit}/files.json"
  files_list = ""
  RestClient::Request.execute(method: :get, url: url, timeout: 300) {|response|
    (JSON.parse(response.body.to_s)).each {|file|
      if file[0] == "error"
        files_list = files_list + file[1] + "\n"
      else
        files_list = files_list + file[0] + "\n"
      end
    }
  }
  return files_list
end

def create_worksheet(book, host, sheet_name, since_time, until_time, repo_manifest, branch, file_list, list_owner)
  sheet = book.create_worksheet :name => "#{sheet_name}"
  set_meta(sheet, since_time, until_time, branch)

  begin
    row = 4
    commits = get_commits(host, repo_manifest, branch, since_time, until_time)
    commits.each {|commit|
      if list_owner == "true" && !commit["author"].include?("arima")
        next
      else
        commit_id = commit["commit"]
        message = commit["message"]
        project = commit["project"]

        risk_area = extract(message, "riskarea:\n?(.*)")
        impacted_group = extract(message, "impacted group:\n?(.*)")
        fix_issue = extract(message, "arima(.*)")
        feature = extract(message, "feature:\n?(.*)")
        root_cause = extract(message, "root cause:\n?(.*)")
        how_to_fix = extract(message, "how to fix:\n?(.*)")

        sheet[row, 0] = commit_id
        sheet[row, 1] = commit["committer_time"]
        sheet[row, 2] = commit["message"].split("\n").first
        sheet[row, 3] = commit["author"]
        sheet[row, 4] = risk_area
        sheet[row, 5] = fix_issue
        sheet[row, 6] = feature
        sheet[row, 7] = root_cause
        sheet[row, 8] = how_to_fix
        sheet[row, 9] = project
        sheet[row, 10] = message

        if file_list == 'true'
          sheet[row, 11] = get_files(host, project, commit_id)
        end
        row = row + 1
      end
    }
  rescue RestClient::NotFound => e
    puts e.message
    puts e.response
  end
end

host = ENV["host"]
branch_amss= ENV["amss_branch"]
branch_android = ENV["android_branch"]
since_time = ENV["previous"]
until_time = ENV["current"]
since_time = DateTime.strptime("#{since_time}", '%Y%m%d.%H%M%S').strftime("%Y-%m-%d %H:%M:%S")
until_time = DateTime.strptime("#{until_time}", '%Y%m%d.%H%M%S').strftime("%Y-%m-%d %H:%M:%S")
output = ENV["project"] + "-changenote-" + ENV["previous"] + "-diff-" + ENV["current"] + ".xls"

file_list = ENV["file_list"]
list_owner = ENV["arima_owner"]

begin
  book = Spreadsheet::Workbook.new
  create_worksheet(book, host, "amss", since_time, until_time, "platform/amssmanifest", branch_amss, file_list, list_owner)
  create_worksheet(book, host, "android", since_time, until_time, "platform/manifest", branch_android, file_list, list_owner)
  book.write "#{output}"
rescue RestClient::BadRequest => e
  puts e.response
rescue RestClient::NotFound => e
  puts e.response
end