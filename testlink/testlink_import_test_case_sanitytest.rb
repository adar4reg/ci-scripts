#!/usr/bin/env ruby

require 'csv'
require 'xmlrpc/client'
require 'spreadsheet'

def get_test_project_id
  args = {devKey: @key, testprojectname: 'ANDROID-SANITY-TEST'}
  r = @server.call('tl.getTestProjectByName', args)
  r['id']
end

def create_test_suite(suite)
  args = {devKey: @key, testsuitename: suite, prefix: 'A-SANITY'}
  r = @server.call('tl.getTestSuite', args)
  if r.size == 0
    args = {devKey: @key, testprojectid: @test_project_id, testsuitename: suite}
    r = @server.call('tl.createTestSuite', args)
  end
  r[0]['id']
end

def create_test_case(suite, testcasename, summary, preconditions, steps)
  test_suite_id = create_test_suite(suite)
  args = {devKey: @key, testprojectid: @test_project_id, testsuiteid: test_suite_id, testcasename: testcasename, authorlogin: 'dicktsai', preconditions: preconditions, summary: summary, steps: steps}
  r = @server.call('tl.createTestCase', args)
  puts r
end

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"
@test_project_id = get_test_project_id

Spreadsheet.client_encoding = 'UTF-8'

book = Spreadsheet.open '/media/d/workspace/Sanity_format_20191211.xls'

book.worksheets
sheet1 = book.worksheet 'list'

sheet1.each do |row|
  if row[0] != nil && row[1] == nil && row[2] == nil && row[3] == nil
    @category = row[0]
  end
  if row[0] != nil && row[1] != nil
    @id = row[0]
    @step_array = []
    @testcase_name = row[1]
    @summary = row[2].gsub("\n","<\p>\n<p>")
    @precondition = row[3].to_s	.gsub("\n","<\p>\n<p>")
    @step_array = []
    sheet1.each do |row|
      if (row[0] != nil && row[1] != nil) || (row[0] == nil && row[1] == nil)
        @step_id = row[0].to_s
        if @step_id.size != 0
          @step = 1
          @id_bak = @step_id
        else
          @step += 1
          @step_id = @id_bak
        end
        if @id == @step_id
          if row[4][0..1].to_s.include?('.')
            @step_description = row[4][2..500].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
          elsif row[4][0..2].to_s.include?('.')
            @step_description = row[4][3..500].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
          else
            @step_description = row[4][0..500].gsub("\n","<\p>\n<p>")
          end
          if row[5][0..1].to_s.include?('.')
            @expectedresult = row[5][2..500].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
          elsif row[5][0..2].to_s.include?('.')
            @expectedresult = row[5][3..500].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
          else
            @expectedresult = row[5][0..500].gsub("\n","<\p>\n<p>")
          end
          @step_hash = {step_number: @step,  actions: @step_description, expected_results: @expectedresult, execution_type: '1'}
          @step_array.push(@step_hash)
        end
      end
    end
    @testcase_name = @id + ": " + @testcase_name
    create_test_case(@category, @testcase_name, @summary, @precondition, @step_array)
  end
end
