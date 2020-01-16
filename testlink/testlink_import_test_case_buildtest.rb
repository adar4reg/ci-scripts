#!/usr/bin/env ruby

require 'csv'
require 'xmlrpc/client'
require 'spreadsheet'

def get_test_project_id
  args = {devKey: @key, testprojectname: 'ANDROID-BUILD-TEST'}
  r = @server.call('tl.getTestProjectByName', args)
  r['id']
end

def get_test_case_id(testcasename)
  args = {devKey: @key,  testcasename: testcasename}
  r = @server.call('tl.getTestCaseIDByName', args)
  r[0]['id']
end

def create_test_suite(suite)
  args = {devKey: @key, testsuitename: suite, prefix: 'RBT'}
  r = @server.call('tl.getTestSuite', args)
  if r.size == 0
    args = {devKey: @key, testprojectid: @test_project_id, testsuitename: suite}
    r = @server.call('tl.createTestSuite', args)
  end
  r[0]['id']
end

def create_test_case(suite, testcasename, summary, steps)
  test_suite_id = create_test_suite(suite)
  args = {devKey: @key, testprojectid: @test_project_id, testsuiteid: test_suite_id, testcasename: testcasename, authorlogin: 'dicktsai', summary: summary, steps: steps}
  r = @server.call('tl.createTestCase', args)
  puts r
end

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"
@test_project_id = get_test_project_id

Spreadsheet.client_encoding = 'UTF-8'

book = Spreadsheet.open '/media/d/workspace/01_script/testlink/SWIT_Build_Test_Report.xls'
book.worksheets

sheet1 = book.worksheet 'TestCases'
sheet2 = book.worksheet 'TestSteps'

sheet1.each 1 do |row|
  if row[0].to_s != ""
    tcid = row[0]
    variant = row[1]
    category = row[2]
    testcasename = row[3]
    description = row[4].lstrip.rstrip.gsub("\n","<\p>\n<p>")
#    tester = row[5]
#    result = row[6].lstrip.rstrip.gsub("\n","<\p>\n<p>")
#    notes = row[7]

    @step_array = []
    sheet2.each 1 do |row|
      id = row[0].to_s
      step = row[1].gsub("Step","").lstrip.rstrip.to_s.gsub("\n","<\p>\n<p>")
      step_description = row[2].lstrip.rstrip.to_s.gsub("\n","<\p>\n<p>")
      if row[3] != nil
        expectedresult = row[3].lstrip.rstrip.to_s.gsub("\n","<\p>\n<p>")
      else
        expectedresult = row[3].to_s.gsub("\n","<\p>\n<p>")
      end
      if id.size != 0
        @id_bak = id
      else
        id = @id_bak
      end
      if id == tcid
        step_hash = {step_number: step,  actions: step_description, expected_results: expectedresult, execution_type: '1'}
        @step_array.push(step_hash)
      end
    end
    create_test_case(category, testcasename, description, @step_array)
  end
end
