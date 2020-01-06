require 'rest-client'
require 'json'
require 'spreadsheet'
require_relative 'fossy'

run_project =  ARGV[0]

def cws(book, version, time_until, time_since, branch)
  url = 'http://review.arimacomm.com.tw/manifests/diff'
  repository = 'platform%2Fmanifest'
  sheet = book.create_worksheet :name => "#{version}"
  sheet[0, 0] = "Commit"
  sheet[0, 1] = "Commit Author"
  sheet[0, 2] = "Project"
  sheet[0, 3] = "Subject"
  sheet[0, 4] = "File"
  sheet[0, 5] = "Status"
  sheet[0, 6] = "Binary"
  sheet[0, 7] = "Modify by Arima"
  sheet[0, 8] = "Size"
  sheet[0, 9] = "License"
  sheet[0, 10] = "Copyright"
  r = RestClient.get "#{url}?repository=#{repository}&branch=#{branch}&since=#{time_since}&until=#{time_until}"
  commits = JSON.parse(r.to_s)
  index = 1
  commits.each do |commit|
    commit_id = commit['commit']
    commit_desc = commit['message'].lines.first.chomp
    project = commit['project']
    commit_project = commit['project'].gsub('/', '%2F')
    commit_author = commit['author']
    r = RestClient.get "http://review.arimacomm.com.tw:8080/a/projects/#{commit_project}/commits/#{commit['commit']}/files/"
    files = JSON.parse(r.to_s[5..-1])
    files.each do |file|
      if (file[0] != '/COMMIT_MSG') && (file[0] != '/MERGE_LIST')
        status = file[1]['status'].nil? ? 'M' : file[1]['status']
        file_encoded = file[0].gsub('/', '%2F')
        file_size = file[1]['size']
        if file[1]['binary'].nil?
          binary = "FALSE"
          if (commit["author"].include? "arimacomm")
            modify_by_arima = "TRUE"
            if status != "D"
              begin
                r = RestClient.get "http://review.arimacomm.com.tw:8080/a/projects/#{commit_project}/commits/#{commit_id}/files/#{file_encoded}/content"
                tempfile = Tempfile.new()
                tempfile.write(Base64.decode64(r.to_s))
                tempfile.close
                info = info(tempfile.path)
                license = info[0]
                copyright = info[1]
              rescue
                license = "file empty"
              end
            else
              license = "File Delete"
            end
          else
            modify_by_arima = "FALSE"
            if (status == "D")
              license = "File Delete"
            else
              license = ""
            end
          end
        else
          if (commit_author.include? "arimacomm")
            modify_by_arima = "TRUE"
          else
            modify_by_arima = "FALSE"
          end
          if (status == "D")
            license = "File Delete"
          else
            license = ""
          end
          binary = "TRUE"
        end
        sheet[index, 0] = commit_id
        sheet[index, 1] = commit_author
        sheet[index, 2] = project
        sheet[index, 3] = commit_desc
        sheet[index, 4] = file[0]
        sheet[index, 5] = status
        sheet[index, 6] = binary
        sheet[index, 7] = modify_by_arima
        sheet[index, 8] = file_size
        sheet[index, 9] = license
        sheet[index, 10] = copyright
        index += 1
      end
    end
  end
  sheet.column(1).width = 36.29
  sheet.column(3).width = 29.29
end


def cws2(book, version, commitid_file)
  index = 1
  sheet = book.create_worksheet :name => "#{version}"
  sheet[0, 0] = "Commit"
  sheet[0, 1] = "Commit Author"
  sheet[0, 2] = "Project"
  sheet[0, 3] = "Subject"
  sheet[0, 4] = "File"
  sheet[0, 5] = "Status"
  sheet[0, 6] = "Binary"
  sheet[0, 7] = "Modify by Arima"
  sheet[0, 8] = "Size"
  sheet[0, 9] = "License"
  sheet[0, 10] = "Copyright"
  text=File.open(commitid_file).read
  text.each_line do |line|
    commit_id = line.chomp
    begin
      r = RestClient.get "http://review.arimacomm.com.tw:8080/a/changes/#{commit_id}/detail"
      r = JSON.parse(r.to_s[5..-1])
      project = r["project"]
      commit_project = r["project"].gsub('/', '%2F')
      commit_desc = r["subject"]
      r = RestClient.get "http://review.arimacomm.com.tw:8080/a/projects/#{commit_project}/commits/#{commit_id}"
      r = JSON.parse(r.to_s[5..-1])
      commit_author = r["author"]["email"]
      r = RestClient.get "http://review.arimacomm.com.tw:8080/a/projects/#{commit_project}/commits/#{commit_id}/files/"
      files = JSON.parse(r.to_s[5..-1])
      files.each do |file|
        if (file[0] != '/COMMIT_MSG') && (file[0] != '/MERGE_LIST')
          status = file[1]['status'].nil? ? 'M' : file[1]['status']
          file_encoded = file[0].gsub('/', '%2F')
          file_size = file[1]['size']
          if file[1]['binary'].nil?
            binary = "FALSE"
            if (commit_author.include? "arimacomm")
              modify_by_arima = "TRUE"
              if status != "D"
                begin
                  r = RestClient.get "http://review.arimacomm.com.tw:8080/a/projects/#{commit_project}/commits/#{commit_id}/files/#{file_encoded}/content"
                  tempfile = Tempfile.new()
                  tempfile.write(Base64.decode64(r.to_s))
                  tempfile.close
                  info = license(tempfile.path)
                  license = info[0]
                  copyright = info[1]
                rescue
                  license = "file empty"
                end
              else
                license = "File Delete"
              end
            else
              modify_by_arima = "FALSE"
              if (status == "D")
                license = "File Delete"
              else
                license = ""
              end
            end
          else
            if (status == "D")
              license = "File Delete"
            else
              license = ""
            end
            if (commit_author.include? "arimacomm")
              modify_by_arima = "TRUE"
            else
              modify_by_arima = "FALSE"
            end
            binary = "TRUE"
          end
          sheet[index, 0] = commit_id
          sheet[index, 1] = commit_author
          sheet[index, 2] = project
          sheet[index, 3] = commit_desc
          sheet[index, 4] = file[0]
          sheet[index, 5] = status
          sheet[index, 6] = binary
          sheet[index, 7] = modify_by_arima
          sheet[index, 8] = file_size
          sheet[index, 9] = license
        sheet[index, 10] = copyright
          index += 1
        end
      end
    rescue
    end
  end
  sheet.column(1).width = 36.29
  sheet.column(3).width = 29.29
end

book = Spreadsheet::Workbook.new

case run_project
when "1"
  cws2(book, "43.0.A.4.59-43.0.A.4.46", "pinecommitid.txt")
  cws(book, "43.0.A.7.70-43.0.A.7.55", "2018-07-26+22%3A02%3A00", "2018-04-27+22%3A02%3A00", "n-mekong-pine-release")
  cws(book, "43.0.A.7.89-43.0.A.7.70", "2018-10-29+22%3A03%3A00", "2018-07-26+22%3A02%3A00", "n-mekong-pine-release")
  cws(book, "43.0.A.7.99-43.0.A.7.89", "2019-01-17+22%3A07%3A00", "2018-10-29+22%3A03%3A00", "n-mekong-pine-release")
  cws(book, "43.0.A.7.106-43.0.A.7.99", "2019-04-23+22%3A07%3A00", "2019-01-17+22%3A07%3A00", "n-mekong-pine-release")
  book.write "/media/d/workspace/share_437/pine.xls"
when "2"
  cws2(book, "49.0.A.6.46-49.0.A.5.70", "rangercommitid.txt")
  cws(book, "49.0.A.6.56-49.0.A.6.46", "2018-10-29+21%3A00%3A00", "2018-08-31+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.67-49.0.A.6.56", "2019-01-21+21%3A00%3A00", "2018-10-29+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.80-49.0.A.6.67", "2019-04-26+11%3A58%3A00", "2019-01-21+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.90-49.0.A.6.80", "2019-07-25+21%3A00%3A00", "2019-04-26+11%3A58%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.96-49.0.A.6.90", "2019-09-11+21%3A00%3A00", "2019-07-25+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.102-49.0.A.6.96", "2019-11-20+21%3A00%3A00", "2019-09-11+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  cws(book, "49.0.A.6.107-49.0.A.6.102", "2019-12-10+21%3A00%3A00", "2019-11-20+21%3A00%3A00", "n-mr1-mekong-ranger-release")
  book.write "/media/d/workspace/share_437/ranger.xls"
when "3"
  cws(book, "36.1.A.1.112-36.1.A.1.106", "2019-03-21+09%3A52%3A00", "2018-02-24+10%3A58%3A00", "n-kabini-ukulele-release")
  book.write "/media/d/workspace/share_437/ukulele.xls"
when "4"
  cws(book, "36.1.A.1.112-36.1.A.1.106", "2019-03-21+09%3A52%3A00", "2018-02-24+10%3A58%3A00", "n-kabini-ukulele-release")
  book.write "/media/d/workspace/share_437/test.xls"
end

