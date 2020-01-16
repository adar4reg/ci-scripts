#!/usr/bin/env ruby

require 'csv'
require 'xmlrpc/client'
require 'spreadsheet'

def get_test_project_id
  args = {devKey: @key, testprojectname: 'ANDROID-SMOKE-TEST'}
  r = @server.call('tl.getTestProjectByName', args)
  r['id']
end

def create_test_suite(suite)
  args = {devKey: @key, testsuitename: suite, prefix: 'A-SMOKE'}
  r = @server.call('tl.getTestSuite', args)
  if r.size == 0
    args = {devKey: @key, testprojectid: @test_project_id, testsuitename: suite}
    r = @server.call('tl.createTestSuite', args)
  end
  r[0]['id']
end

def create_test_case(suite, testcasename, summary)
  test_suite_id = create_test_suite(suite)
  args = {devKey: @key, testprojectid: @test_project_id, testsuiteid: test_suite_id, testcasename: testcasename, authorlogin: 'dicktsai',summary: summary,steps: ''}
  r = @server.call('tl.createTestCase', args)
  puts r
end

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"
@test_project_id = get_test_project_id

Spreadsheet.client_encoding = 'UTF-8'

book = Spreadsheet.open '/media/d/workspace/Smoke_Test_Report.xls'

book.worksheets
sheet1 = book.worksheet 'Smoke Test Report'

sheet1.each do |row|
  if row[0] != nil
    suite = row[0]
    @suite_bak = suite
  else
    suite = @suite_bak
  end
  testcasename = row[1]
  summary = "Verify " + row[1]
  create_test_suite(suite)
  create_test_case(suite, testcasename, summary)
end
