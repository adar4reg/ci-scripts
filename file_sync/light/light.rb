load 'light_synchronize.rb'

# use aws s3
# download s3cmd-master/s3cmd
# sync /media/d/workspace/tmp2/com/arimacomm/4101/ to s3://light-two-artifactory-sync

def datetime
  return DateTime.now.strftime("%Y-%m-%d %H:%M")
end

from = "artifactory.arimacomm.com.tw"
to = "/media/d/workspace/tmp2"
aql = 'items.find({"repo":{"$eq":"share-light"}})'

SyncLocal.class_variable_set(:@@logger, Logger.new("/var/log/replication/sync-light.log", "daily"))

while (true) do
  SyncLocal.replicate(aql, from, to)
  `/home/administrator/bin/s3cmd-master/s3cmd sync /media/d/workspace/tmp2/com/arimacomm/4101/ s3://light-two-artifactory-sync`
  puts datetime + " .. sleep 3600 seconds .."
  sleep 3600
end
