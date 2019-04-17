require 'builder'

def create_xml(testcase)
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.configuration(description: "Run Sanity Test") do |t|
    t.test(class: "com.arima.autotest.tradefed.FastbootTest") do |o|
      o.option(name: "flasher-class", value: "com.arima.autotest.tradefed.targetprep.GenericDeviceFlashPreparer")
    end
    testcase.each do |tc|
      t.test(class: "com.arima.autotest.tradefed.#{tc}")
    end
    t.result_reporter(class: "com.arima.autotest.tradefed.result.XmlResultReporter")
    t.logger(class: "com.android.tradefed.log.FileLogger")
  end
end

testcase = ARGV[0].split(",")

file = File.new("test.xml", "w")
file.puts(create_xml(testcase))
file.close
