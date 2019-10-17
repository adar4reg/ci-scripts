require 'date'

# use lftp
# apt-get install lftp
# sync nj ftp / to /home/administrator/server-M'

def datetime
  return DateTime.now.strftime("%Y-%m-%d %H:%M")
end

def sync()
  return "lftp -f ftp_sync_nj.lftp"
end

while (true) do
  begin
    puts "sync NJ_FTP to M start"
    start_time = datetime
    system sync()
    puts "sync NJ_FTP to M end"
    end_time = "#{datetime}"
    puts "sync start #{start_time}"
    puts "sync end #{end_time}"
  rescue
    puts "something wrong there"
  end
  puts " .. sleep 300 seconds .."
  puts ""
  sleep 300
end
