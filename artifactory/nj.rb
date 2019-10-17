load 'artifactory_replication.rb'

from = 'artifactory.arimacomm.com.tw'
to = 'artifactory.arimatech.com.cn'
aqls = [
'items.find({"created":{"$last":"1d"}},{"name":{"$nmatch":"*9970*"}},{"repo":{"$eq":"share-somc"}},{"path":{"$match":"*/C2D/*"}})',
'items.find({"created":{"$last":"3d"}},{"name":{"$nmatch":"*9970*"}},{"repo":{"$eq":"libs-staging-local"}},{"name":{"$match":"*image*"}})'
]

ArtifactoryReplication.class_variable_set(:@@logger, Logger.new("/var/log/replication/replication.log", "daily"))

while (true) do
  ArtifactoryReplication.replicate(aqls[0], from, to)
  ArtifactoryReplication.replicate(aqls[1], from, to)
  puts "... wait 60s ..."
  sleep 60
end
