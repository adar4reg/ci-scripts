require 'date'

# use unison/seafile
#
#

function = ARGV.length == 0 ? 'start' : ARGV.first

def datetime
  return DateTime.now.strftime("%Y-%m-%d %H:%M")
end

def seafcli_sync(libraryid, server, folder)
  system "seaf-cli sync -l #{libraryid} -s #{server} -d #{folder} -u dicktsai@arimacomm.com.tw -p dicktsai"
end

def seafcli_desync(folder)
  system "seaf-cli desync -d #{folder}"
end

def sync()
  seafile_tp = "http://seafile.arimacomm.com.tw"
  seafile_nj = "http://seafile.arimatech.com.cn"
  seafcli_sync("f51687ac-f37c-4bd9-9152-94c1da93dea2", "#{seafile_tp}", "/media/d/seafile/seafile_tp/monkeylog/")
  seafcli_sync("d8a64877-dec0-4013-a66b-85dc0ebce5d8", "#{seafile_tp}", "/media/d/seafile/seafile_tp/gms/")
  seafcli_sync("18f2acb9-7601-4f03-b848-f799188839f1", "#{seafile_nj}", "/media/d/seafile/seafile_nj/monkeylog/")
  seafcli_sync("7249a3b6-fd8d-4e3c-85e0-8eb442a034fd", "#{seafile_nj}", "/media/d/seafile/seafile_nj/gms/")
end

def desync()
  seafcli_desync("/media/d/seafile/seafile_tp/monkeylog/")
  seafcli_desync("/media/d/seafile/seafile_tp/gms/")
  seafcli_desync("/media/d/seafile/seafile_nj/monkeylog/")
  seafcli_desync("/media/d/seafile/seafile_nj/gms/")
end

def run()
  while (true) do
    begin
      system "unison sync"
    rescue
      puts "something wrong there"
    end
    puts " .. sleep 60 seconds .."
    puts ""
    sleep 60
  end
end

case function.downcase
when 'start'
  system "seaf-cli start"
when 'stop'
  system "seaf-cli stop"
when 'sync'
  sync
when 'desync'
  desync
when 'run'
  run
end

