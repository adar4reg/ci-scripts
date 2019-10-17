require 'nokogiri'
require 'rest-client'
require 'json'
require 'concurrent'
require 'chatwork'

def cdf_link(cdf, project_name, project_cdf_version)
  folder_link = "http://somc-c2d.arimacomm.com.tw/pool/cdf/c/cdf-#{project_name}-#{cdf}-generic-ggl/"
  page = Nokogiri::HTML(RestClient.get(folder_link))
  filename = ((page.xpath("//table/tr/td/a[contains(@href, '#{project_cdf_version}')]/@href").collect { |href| href.value }).sort())[-1]
  return "#{folder_link}#{filename}"
end

def docker_cmd(cmd)
  image="docker.arimacomm.com.tw/jenkins/somc-c2d/somc-c2d-client:1.0"
  c2d_server="androidswrepo.global.sonyericsson.net:192.168.251.101"
  return "docker run -t -e DEV_UID=\$(id -u) -e DEV_GID=\$(id -g) -v $(pwd):$(pwd) -w $(pwd) --rm --add-host #{c2d_server} #{image} bash -c \"#{cmd}\""
end

def artifactory_cmd(filename, path, props, username, password)
  artifactory_url = "http://artifactory.arimacomm.com.tw:8081/artifactory/"
  return "JFROG_CLI_OFFER_CONFIG=false jfrog rt u -user #{username} --password #{password} --url #{artifactory_url} --props='#{props}' #{filename} #{path}"
end

def copy_file(artifactory_path, filename_copy, repo_gst, username, password)
  artifactory_url = "http://artifactory.arimacomm.com.tw:8081/artifactory/"
  return "JFROG_CLI_OFFER_CONFIG=false jfrog rt cp -user #{username} --password #{password} --url #{artifactory_url} #{artifactory_path}#{filename_copy} #{repo_gst}"
end

def artifactory_file_exist?(artifact, version)
  r = RestClient.get "http://artifactory.arimacomm.com.tw:8081/artifactory/api/search/gavc?a=#{artifact}&v=#{version}"
  return (JSON.parse(r))["results"].size == 0 ? false : true
end

def get_label_metadata(label, attribute)
  return `#{docker_cmd("repository labelmetadata #{label}")}`.match(/#{attribute}: (.*)\x0D\x0A/)[1]
end

def get_product(project_products, label)
  return project_products[label[0..5]]
end

def datetime
  return DateTime.now.strftime("%d/%m/%Y %H:%M")
end

username = ""
password = ""

label_filter = "^(43\.0\.[AC]|49\.0\.A|36\.[01]\.[AB]|29\.2\.[AB]|27\.3\.[AB].[01])"
project_products = {
"49.0.A" => {"gina-ds" => "1311-7021", "gina-ss" => "1311-6580", "rex" => "1311-6594", "gina-apac-ds" => "1311-7022"},
"43.0.A" => {"gina-ss" => "1307-3090", "gina-ds" => "1307-3089", "rex" => "1307-3088"},
"43.0.B" => {"gina-ds" => "1307-3089"},
"43.0.C" => {"gina-ss" => "1307-3090"},
"36.0.A" => {"gina-ss" => "1300-9758", "rex" => "1301-0035", "gina-apac-ss" => "1301-0036"},
"36.0.B" => {"gina-ds" => "1301-0037", "gina-apac-ds" => "1301-0038"},
"36.1.A" => {"gina-apac-ds" => "1301-0038", "gina-ss" => "1300-9758", "gina-ds" => "1301-0037", "rex" => "1301-0035", "gina-apac-ss" => "1301-0036"},
"29.2.A" => {"rex" => "1296-3699", "gina-apac-ss" => "1296-3697"},
"29.2.B" => {"gina-ds" => "1296-3698", "gina-apac-ds" => "1296-3696"},
"27.3.A" => {"gina-ss" => "1293-5439", "rex" => "1293-5448", "gina-apac-ss" => "1293-5445"},
"27.3.B" => {"gina-ds" => "1293-5443", "gina-apac-ds" => "1293-5446", "samba" => "1293-5440"}
  }
project_cdf_versions = {"49.0" => ".deb", "43.0" => ".deb", "36.0" => "A_all.deb", "36.1" => "B_all.deb", "27.3" => "B_all.deb", "29.2" => "B_all.deb"}
project_numbers = {"49" => "8103", "43" => "8100", "36" => "5929", "27" => "5918", "29" => "5888"}
project_names = {"49" => "ranger", "43" => "pine", "36" => "ukulele", "27" => "cosmos", "29" => "lavender"}
debug_project_names = {"49" => "ranger", "43" => "pine", "36" => "ukulele", "27.3.A" => "cosmosss", "27.3.B" => "cosmosds", "29.2.A" => "lavenderss", "29.2.B" => "lavenderds"}
variants = ["user", "userdebug", "eng"]

ChatWork.api_key = "ae9a324f4cc3cca7a3a4bb1688cf99c3"
while (true) do
  begin
    pool = Concurrent::FixedThreadPool.new(3)
    pool2 = Concurrent::FixedThreadPool.new(3)

    labels = `#{docker_cmd("repository listlabels -g '#{label_filter}' -dca 7days")}`.split("\r\n")
    labels.each { |label|
      if (label.match('\A[0-9]{2}\.[0-9]\.[A-Z]\.[0-9]\.[0-9]{1,3}\Z'))
        products = get_product(project_products, label)
        project_number = project_numbers[label[0..1]]
        project_name = project_names[label[0..1]]
        project_cdf_version = project_cdf_versions[label[0..3]]
        puts "#{label}: check image"
        arima_version = get_label_metadata(label, "XB-VENDOR-Release-Version")
        props = "arima_version=#{arima_version}"
        version = "#{label}-#{arima_version}"
        products.keys.each { |product|
          cdf = products[product]
          variants.each { |variant|
            if (!artifactory_file_exist?("#{product.upcase}", "#{version}-#{variant.upcase}"))
              root = Dir.pwd
              pool.post do
                folder =  "#{product.upcase}/#{version}-#{variant.upcase}"
                full_folder = "#{root}/#{folder}"
                filename = "./#{product.upcase}-#{version}-#{variant.upcase}-image.zip"
                filename_copy = "#{product.upcase}-#{version}-#{variant.upcase}-image.zip"
                artifactory_path = "share-somc/com/arimacomm/#{project_number}/C2D/#{folder}/"
                repo_gst = "share-gst"

                system "mkdir -p #{full_folder}"
                download_command="semcpkgtoimg #{cdf_link(cdf, project_name, project_cdf_version)} -src #{label}@http://androidswrepo.global.sonyericsson.net result-flashable variant-#{variant} -out #{full_folder}"
                system docker_cmd(download_command)
                pool2.post do
                  system "zip -j -0 -m #{filename} #{full_folder}/*.zip"
                  system artifactory_cmd(filename, artifactory_path, props, username, password)
                  system copy_file(artifactory_path, filename_copy, repo_gst, username, password)
                  system "rm -rf #{full_folder} #{filename}"
                  tmp = "(dance) #{filename} http://artifactory.arimacomm.com.tw:8081/artifactory/#{artifactory_path}#{filename}"
                  if (artifactory_file_exist?("#{product.upcase}", "#{version}-#{variant.upcase}"))
                    ChatWork::Message.create(room_id: 91748499, body: tmp)
                    ChatWork::Message.create(room_id: 58244705, body: tmp)
                  end
                end
              end
            end
          }
        }

        if (!label.match('\A27|29\.[0-9]\.[A-Z]\.[0-9]\.[0-9]{1,3}\Z'))
          puts "#{label}: check debug package"
          product = "DEBUG"
          variants.each { |variant|
            if (!artifactory_file_exist?("#{product.upcase}", "#{version}-#{variant.upcase}"))
              root = Dir.pwd
              pool.post do
                folder =  "#{product.upcase}/#{version}-#{variant.upcase}"
                full_folder = "#{root}/#{folder}"
                filename = "./#{product.upcase}-#{version}-#{variant.upcase}-package.zip"
                artifactory_path = "share-somc/com/arimacomm/#{project_number}/C2D/#{folder}/"
                if (label.match('\A27\.[0-9]\.[A-Z]\.[0-9]\.[0-9]{1,3}\Z'))
                  debug_project_name = debug_project_names[label[0..5]]
                else
                  debug_project_name = debug_project_names[label[0..1]]
                end
                cmd = "repository list #{label} -lc debug | grep debug-system-#{debug_project_name}-#{variant}-release"
                debug_package = `#{docker_cmd(cmd)}`
                system docker_cmd("repository getpackage -o #{full_folder} #{debug_package}")
                pool2.post do
                  system "cd #{full_folder}; ar vx *.deb"
                  system "zip -j -0 -m #{filename} #{full_folder}/debian-binary #{full_folder}/*.gz"
                  system artifactory_cmd(filename, artifactory_path, props)
                  system "rm -rf #{full_folder} #{filename}"
                end
              end
            end
          }
        end
      end
    }
  rescue
    puts "something wrong there"
  ensure
    pool.shutdown
    pool.wait_for_termination
    pool2.shutdown
    pool2.wait_for_termination
  end

  puts "sleep 300 seconds .................."
  sleep 300
end
