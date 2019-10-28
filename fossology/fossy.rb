require 'rest-client'
require 'json'
require 'nokogiri'
require 'base64'

def do_get(url, headers)
  begin
    r = RestClient.get url, headers
    return r
  rescue RestClient::ExceptionWithResponse => e
    puts e.response
  end
end

def do_post(url, payload, headers)
  begin
    r = RestClient.post url, payload, headers
    return r
  rescue RestClient::ExceptionWithResponse => e
    puts e.response
  end
end

def upload(token, url, folder_id, file_name)
  payload = { multipart: true, fileInput: File.new(file_name, 'rb') }
  headers = { Authorization: 'Bearer ' + token, folderId: folder_id }
  r = do_post("#{url}/uploads", payload, headers)
  JSON.parse(r)['message']
end

def analyze(token, url, folder_id, upload_id)
  payload = '{"analysis":{"monk":true, "nomos":true}}'
  headers = { Authorization: 'Bearer ' + token, folderId: folder_id, uploadId: upload_id, content_type: :json}
  do_post("#{url}/jobs", payload, headers)
end

def report(token, url, upload_id)
  headers = { Authorization: 'Bearer ' + token, uploadId: upload_id, reportFormat: 'spdx2'}
  r = do_get("#{url}/report", headers)
  JSON.parse(r)['message'].split('/').last
end

def download(token, url, report_id)
  headers = { Authorization: 'Bearer ' + token}
  r = do_get("#{url}/report/#{report_id}", headers)
  report = Nokogiri::XML r.to_s
  report.xpath('//spdx:licenseInfoInFile').each do |license|
    return license.attr('rdf:resource')
  end
  return 'NA'
end

def license(filename)
  url = 'http://user-test.arimacomm.com.tw:8081/repo/api/v1'
  token ='eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ1c2VyLXRlc3QuYXJpbWFjb21tLmNvbS50dyIsImF1ZCI6InVzZXItdGVzdC5hcmltYWNvbW0uY29tLnR3IiwiZXhwIjoxNTcyMTM0Mzk5LCJuYmYiOjE1Njk0NTYwMDAsImp0aSI6Ik1pNHoiLCJzY29wZSI6IndyaXRlIn0.GUUypRk0X2xk521ZyltwPP4-hBRP-ZI_fyuPKLlNxys'
  folder_id = '1'
  upload_id = upload(token, url, folder_id, filename)
  sleep(5)
  analyze(token, url, folder_id, upload_id)
  report_id = report(token, url, upload_id)
  sleep(5)
  download(token, url, report_id)
end

