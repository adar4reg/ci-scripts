#!/usr/bin/env ruby

require 'csv'
require 'xmlrpc/client'
require 'spreadsheet'

xlsfile = ARGV[0]

def get_test_project_id
  args = {devKey: @key, testprojectname: 'DEMO'}
  r = @server.call('tl.getTestProjectByName', args)
  r['id']
end

def create_test_suite(suite, parentid)
  if parentid == ''
    args = {devKey: @key, testsuitename: suite, prefix: 'DEMO'}
    r = @server.call('tl.getTestSuite', args)
    if r.size == 0
      @args = {devKey: @key, testprojectid: @test_project_id, testsuitename: suite}
      r = @server.call('tl.createTestSuite', @args)
    end
    id = r[0]['id']
  else
    args = {devKey: @key, testsuiteid: parentid}
    r = @server.call('tl.getTestSuitesForTestSuite', args)
    @action = 'create'
    if r.size != 0
      if r.has_key? 'name'
        if r['name'] == suite
          id = r['id']
          @action = ''
        end
      else
        r.each {|hash| 
          if hash[1]['name'] == suite
            id = hash[1]['id']
            @action = ''
            break
          end
        }
      end
    end
    if @action == 'create'
      @args = {devKey: @key, testprojectid: @test_project_id, testsuitename: suite, parentid: parentid}
      r = @server.call('tl.createTestSuite', @args)
      id = r[0]['id']
    end
  end
  id
end

def create_test_case(suite, testcasename, summary, preconditions, steps, top_suite_id, importance)
  test_suite_id = create_test_suite(suite, top_suite_id)
  args = {devKey: @key, testprojectid: @test_project_id, testsuiteid: test_suite_id, testcasename: testcasename, authorlogin: 'dicktsai', preconditions: preconditions, summary: summary, steps: steps, importance: importance}
  r = @server.call('tl.createTestCase', args)
  puts r
end

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"
@test_project_id = get_test_project_id

Spreadsheet.client_encoding = 'UTF-8'
path = '/media/d/workspace/st/'
file = path + xlsfile

book = Spreadsheet.open file
sheets = book.worksheets

sheets.each{ |s|
  @suite = s.name
  if @suite == 'Subject' || @suite == 'Subject ' || @suite == 'subject' || @suite == 'subject '
    sheet0 = book.worksheet @suite
    if sheet0[3,8] != nil && sheet0[3,8].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[4,8].lstrip.rstrip
    elsif sheet0[3,7] != nil && sheet0[3,7].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[4,7].lstrip.rstrip
    elsif sheet0[4,8] != nil && sheet0[4,8].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[5,8].lstrip.rstrip
    elsif sheet0[4,7] != nil && sheet0[4,7].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[5,7].lstrip.rstrip
    elsif sheet0[5,8] != nil && sheet0[5,8].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[6,8].lstrip.rstrip
    elsif sheet0[5,7] != nil && sheet0[5,7].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[6,7].lstrip.rstrip
    elsif sheet0[6,8] != nil && sheet0[6,8].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[7,8].lstrip.rstrip
    elsif sheet0[6,7] != nil && sheet0[6,7].downcase.lstrip.rstrip == 'subject'
      @top_suite = sheet0[7,7].lstrip.rstrip
    end
    parentid = ''
    @top_suite = @top_suite.gsub('\\','').gsub('Functionality','').gsub('functionality','').lstrip.rstrip
    @top_suite_id = create_test_suite(@top_suite, parentid)
  end

  sheetname = @suite.downcase.lstrip.rstrip
  if sheetname != 'check point' && sheetname != 'subject' && sheetname !=  'summary' && sheetname !=  'history' && sheetname !=  'abbreviation' && sheetname !=  'history' && sheetname != 'top  app'
    sheet1 = book.worksheet @suite
    @suite = @suite.lstrip.rstrip
    parentid = ''
    @test_project_id = get_test_project_id
    sheet1.each do |row|

      if row[0] != nil && row[0].to_s.downcase.match('[a-z][0-9]') && !row[0].to_s.match('\AStep[0-9]{1,3}\Z') && !row[0].to_s.match('\Astep[0-9]{1,3}\Z') || row[0].to_s.downcase.match('^youtube....[0-9]{1,3}') && !row[0].to_s.match('\Acase[0-9]\Z')
        @step_array = []
        @stid = row[0]
        @step = 1
        sheet1.each do |row|
          @info_id = row[0].to_s
          if row[0] != nil && row[0].to_s.downcase.match('[a-z][0-9]') && !row[0].to_s.match('\AStep[0-9]{1,3}\Z') && !row[0].to_s.match('\Astep[0-9]{1,3}\Z') || row[0].to_s.downcase.match('^youtube....[0-9]{1,3}') && !row[0].to_s.match('\Acase[0-9]\Z')
            @info_id_bak = @info_id
          else
            @info_id = @info_id_bak
          end
          if @info_id == @stid
            if row[0] != nil && row[0].to_s.downcase.match('[a-z][0-9]') && !row[0].to_s.match('\AStep[0-9]{1,3}\Z') && !row[0].to_s.match('\Astep[0-9]{1,3}\Z') || row[0].to_s.downcase.match('^youtube....[0-9]{1,3}') && !row[0].to_s.match('\Acase[0-9]\Z')
              @testcasename = row[1]
              @importance = row[4]
              if row[4] == 'H' || row[4] == '1-High'
                @importance = 3
              elsif row[4] == 'M' || row[4] == '2-Medium' || row[4] == '2-Meidum'
                @importance = 2
              elsif row[4] == 'L' || row[4] == '3-Low'
                @importance = 1
              end
            end
            if row[0].to_s.downcase.lstrip.rstrip.include?('preparation') || row[0].to_s.downcase.lstrip.rstrip.include?('precondition')
              if row[1] != nil
                @preconditions = row[1].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
              else
                @preconditions = row[1].to_s
              end
            end
            if row[0].to_s.downcase.include?('purpose')
              @summary = row[1].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
            end
            if row[0] != nil
              if row[0].class == Float || row[0].to_s.match('\A[0-9]{1,3}\Z') || row[0].to_s.match('\AStep[0-9]{1,3}\Z') && !row[0].to_s.match('\Acase[0-9]\Z')
                @step_description = row[1].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
                @expectedresult = row[2].to_s.lstrip.rstrip.gsub("\n","<\p>\n<p>")
                @step_hash = {step_number: @step,  actions: @step_description, expected_results: @expectedresult, execution_type: '1'}
                @step_array.push(@step_hash)
                @step += 1
              end
            end
          end
        end
        @testcasename = @stid.gsub('  ',' ') + ": " + @testcasename
        create_test_case(@suite, @testcasename, @summary, @preconditions, @step_array, @top_suite_id, @importance)
      end
    end
  end
}
