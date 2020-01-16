#!/usr/bin/env ruby

require 'xmlrpc/client'

@test_project = 'DEMO'
@project = '4102'
@copy_from_project = '4101'

def create_test_plan(testprojectname, testplanname)
  args = {devKey: @key, testplanname: testplanname, testprojectname: testprojectname}
  r = @server.call('tl.createTestPlan', args)
  puts r
end

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

def get_test_case_for_test_plan(testplanid)
  args = {devKey: @key, testplanid: testplanid}
  r = @server.call('tl.getTestCasesForTestPlan', args)
  r
end

def add_test_case_to_test_plan(testprojectid, testplanid, testcaseexternalid, version)
  args = {devKey: @key, testprojectid: testprojectid, testplanid: testplanid, testcaseexternalid: testcaseexternalid, version: version.to_i}
  r = @server.call('tl.addTestCaseToTestPlan', args)
  puts r
end

@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')
@key = "a3395724f6e5d163350946345886d571"

@new_test_plan = @project + "-" + @test_project
@old_test_plan = @copy_from_project + "-" + @test_project

create_test_plan(@test_project, @new_test_plan)
@testprojectid = get_test_project_id(@test_project)
@new_testplanid = get_test_plan_id(@test_project, @new_test_plan)


if @copy_from_project.size == 0
  puts "create plan from project"
  suites = get_test_suite_for_project(@testprojectid)
  suites.each { |suite|
    suite_id = suite['id']
    cases = get_test_case_for_suite(suite_id)
    cases.each { |c|
      external_id = c['external_id']
      add_test_case_to_test_plan(@testprojectid, @new_testplanid, external_id, "1")
    }
  }
else
  puts "create plan from other plan"
  @old_testplanid = get_test_plan_id(@test_project, @old_test_plan)
  test_cases = get_test_case_for_test_plan(@old_testplanid)
  test_cases.each { |c|
    external_id = c[1][0]['full_external_id']
    add_test_case_to_test_plan(@testprojectid, @new_testplanid, external_id, "1")
  }
end
