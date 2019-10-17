require 'nokogiri'
require 'rest-client'
require 'json'

def docker_cmd(cmd)
  image="docker.arimacomm.com.tw/jenkins/somc-c2d/somc-c2d-client:1.0"
  c2d_server="androidswrepo.global.sonyericsson.net:192.168.251.101"
  return "docker run -t -e DEV_UID=\$(id -u) -e DEV_GID=\$(id -g) -v $(pwd):$(pwd) -w $(pwd) --rm --add-host #{c2d_server} #{image} bash -c \"#{cmd}\""
end

def get_label_metadata(label, attribute)
  return `#{docker_cmd("repository labelmetadata #{label}")}`.match(/#{attribute}: (.*)\x0D\x0A/)[1]
end

def check_label(project_number, label_mapping, label, datetime)
  if File.open("/home/administrator/server-N/CMBuild/#{project_number}/SOMC_LABEL/SoMC_Arima_mapping.txt").grep(/#{label_mapping}/).size > 0
    puts "=== " + datetime + " === existed label : #{label}"
  else
    puts "=== " + datetime + " === new label : #{label}"
    File.open("/home/administrator/server-N/CMBuild/#{project_number}/SOMC_LABEL/SoMC_Arima_mapping.txt", "a") {|file| file.write("#{label_mapping}""\n")}
  end
end

def datetime
  return DateTime.now.strftime("%d/%m/%Y %H:%M")
end

label_filter = "^(43\.0\.[AC]|49\.0\.A|36\.[01]\.[AB]|29\.2\.[AB]|27\.3\.[AB].[01])"
project_numbers = {"49" => "8103", "43" => "8100", "36" => "5929", "27" => "5916", "29" => "5888"}

while (true) do
  labels = `#{docker_cmd("repository listlabels -g '#{label_filter}' -dca 2days")}`.split("\r\n")
  labels.each { |label|
    if (label.match('\A[0-9]{2}\.[0-9]\.[A-Z]\.[0-9]\.[0-9]{1,3}\Z'))
      project_number = project_numbers[label[0..1]]
      arima_version = get_label_metadata(label, "XB-VENDOR-Release-Version")
      label_mapping = "#{label},#{arima_version}"
      check_label(project_number, label_mapping, label, datetime)
    end
  }
  puts "sleep 120 seconds .................."
  sleep 120
end
