require 'builder'

def create_xml(testcase, project)
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.configuration(description: "Run Sanity Test") do |t|
    t.test(class: "com.arima.autotest.tradefed.FastbootTest") do |o|
      o.option(name: "flasher-class", value: "com.arima.autotest.tradefed.targetprep.GenericDeviceFlashPreparer")
    end
    testcase.each do |tc|
      t.test(class: "com.arima.autotest.tradefed.#{tc}") do |o|
        if tc.eql? "monkey.MonkeyBase"
          o.option(name: "project-name", value: "#{project}")
        end
      end
    end
    t.result_reporter(class: "com.android.tradefed.result.TextResultReporter")
    t.result_reporter(class: "com.arima.autotest.tradefed.result.XmlResultReporter")
  end
end

testcase = ARGV[0].split(",")
project = ARGV[1]

file = File.new("test.xml", "w")
file.puts(create_xml(testcase, project))
file.close
