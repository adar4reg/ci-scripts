#!/usr/bin/env ruby

require 'xmlrpc/client'

@test_project = 'ANDROID-SMOKE'
@project = '6650'
@sw_version = '1.2.3.4'

@key = 'a3395724f6e5d163350946345886d571'
@server = XMLRPC::Client.new2( uri = 'http://testlink.arimacomm.com.tw/testlink/lib/api/xmlrpc/v1/xmlrpc.php')

def get_test_plan_id(testprojectname, testplanname)
  args = {devKey: @key, testprojectname: testprojectname, testplanname: testplanname}
  r = @server.call('tl.getTestPlanByName', args)
  r[0]['id']
end

def create_build(testplanid, buildname)
  args = {devKey: @key, testplanid: testplanid, buildname: buildname}
  r = @server.call('tl.createBuild', args)
  puts r
end

@test_plan = @project + "-" + @test_project
@testplanid = get_test_plan_id(@test_project, @test_plan)
create_build(@testplanid, @sw_version)
