docker run --name cas1 -p 9042:9042 -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -e CASSANDRA_DC=datacenter1 -d cassandra
docker run --name cas2 -p 9043:9042 -e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' cas1)" -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -e CASSANDRA_DC=datacenter1 -d cassandra
docker run --name cas3 -p 9044:9042 -e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' cas1)" -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -e CASSANDRA_DC=datacenter2 -d cassandra


docker exec -it cas2 nodetool status
CREATE KEYSPACE ks WITH replication = { 'class' : 'NetworkTopologyStrategy', 'datacenter1' : 1, 'datacenter2': 1};
CREATE TABLE tbl (id int primary key, name text);
docker exec -ti cas1 nodetool status ks


