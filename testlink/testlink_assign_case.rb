#!/usr/bin/env ruby

require 'xmlrpc/client'

@test_project = 'DEMO'
@project = '6502'
@execute_sw_version = '6502.1.1.1'
@default_tester = ''
@copy_from_project = '6501'
@copy_from_sw_version = '6501.1.1.1'

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"

def get_test_project_id(test_project)
  args = {devKey: @key, testprojectname: test_project}
  r = @server.call('tl.getTestProjectByName', args)
  r['id']
end

def get_test_plan_id(testprojectname, testplanname)
  args = {devKey: @key, testprojectname: testprojectname, testplanname: testplanname}
  r = @server.call('tl.getTestPlanByName', args)
  r[0]['id']
end

def get_test_suite_for_project(testprojectid)
  args = {devKey: @key, testprojectid: testprojectid}
  r = @server.call('tl.getFirstLevelTestSuitesForTestProject', args)
  r
end

def get_test_case_for_suite(testsuiteid)
  args = {devKey: @key, testsuiteid: testsuiteid}
  r = @server.call('tl.getTestCasesForTestSuite', args)
  r
end

def assign_test_case_execution_task(testplanid, testcaseexternalid, buildname, user)
  args = {devKey: @key, testplanid: testplanid, testcaseexternalid: testcaseexternalid, buildname: buildname, user: user}
  r = @server.call('tl.assignTestCaseExecutionTask', args)
  puts r
end

def get_test_case_assigned_tester(testplanid, testcaseexternalid, buildname)
  args = {devKey: @key, testplanid: testplanid, testcaseexternalid: testcaseexternalid, buildname: buildname}
  r = @server.call('tl.getTestCaseAssignedTester', args)
  r
end

def get_test_cases_for_test_plan(testplanid)
  args = {devKey: @key, testplanid: testplanid}
  r = @server.call('tl.getTestCasesForTestPlan', args)
  r
end

@new_test_plan = @project + "-" + @test_project
@testprojectid = get_test_project_id(@test_project)
@new_testplanid = get_test_plan_id(@test_project, @new_test_plan)

if @copy_from_project == nil
  puts "assign default tester to : " + @default_tester.to_s
  cases = get_test_cases_for_test_plan(@new_testplanid)
  cases.each{ |c|
    testcaseexternalid = c[1][0]['full_external_id']
    assign_test_case_execution_task(@new_testplanid, testcaseexternalid, @execute_sw_version, @default_tester)
  }
else
  @old_test_plan = @copy_from_project + "-" + @test_project
  puts "assign tester from plan : " + @old_test_plan.to_s
  @old_testplanid = get_test_plan_id(@test_project, @old_test_plan)
  cases = get_test_cases_for_test_plan(@old_testplanid)
  cases.each{ |c|
    testcaseexternalid = c[1][0]['full_external_id']
    testers = get_test_case_assigned_tester(@old_testplanid, testcaseexternalid, @copy_from_sw_version)
    testers.each{ |tester|
      tester = tester['login']
      assign_test_case_execution_task(@new_testplanid, testcaseexternalid, @execute_sw_version, tester)
    }
  }
end
