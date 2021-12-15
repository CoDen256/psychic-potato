docker run --name cas1 -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -d cassandra
docker run --name cas2 -e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' cas1)" -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -d cassandra
docker run --name cas3 -e CASSANDRA_SEEDS="$(docker inspect --format='{{ .NetworkSettings.IPAddress }}' cas1)" -e CASSANDRA_CLUSTER_NAME=Cluster -e CASSANDRA_ENDPOINT_SNITCH=GossipingPropertyFileSnitch -d cassandra


docker exec -it cas1 nodetool status

CREATE KEYSPACE ks1 WITH replication = { 'class' : 'NetworkTopologyStrategy', 'replication_factor':1};
CREATE KEYSPACE ks2 WITH replication = { 'class' : 'NetworkTopologyStrategy', 'replication_factor':2};
CREATE KEYSPACE ks3 WITH replication = { 'class' : 'NetworkTopologyStrategy', 'replication_factor':3};
CREATE TABLE ks1.table1 (id int primary key, name text);
CREATE TABLE ks2.table1 (id int primary key, name text);
CREATE TABLE ks3.table1 (id int primary key, name text);


docker exec -it cas1 cqlsh
INSERT INTO ks1.table1(id, name) VALUES (1, 'Text 1');
INSERT INTO ks1.table1(id, name) VALUES (2, 'Text 2');
INSERT INTO ks1.table1(id, name) VALUES (3, 'Text 3');
INSERT INTO ks2.table1(id, name) VALUES (4, 'Text 4');
INSERT INTO ks3.table1(id, name) VALUES (5, 'Text 5');
SELECT  * FROM ks1.table1;

docker exec -it cas2 cqlsh
SELECT * FROM ks1.table1;
SELECT * FROM ks2.table1;
SELECT * FROM ks3.table1;
INSERT INTO ks1.table1(id, name) VALUES (6, 'Text 6');
INSERT INTO ks3.table1(id, name) VALUES (7, 'Text 7');

docker exec -it cas3 cqlsh
SELECT * FROM ks1.table1;
SELECT * FROM ks2.table1;
SELECT * FROM ks3.table1;

docker exec -ti cas1 nodetool status ks1
docker exec -ti cas1 nodetool status ks2
docker exec -ti cas1 nodetool status ks3

docker exec -it cas1 nodetool getendpoints ks3 table1 7
docker exec -it cas1 nodetool getendpoints ks2 table1 4
docker exec -it cas1 nodetool getendpoints ks1 table1 1

R + W > N

ks1: N = 1, R = 1, W = 1 - strong consistency
ks2: N = 2, R = 1, W = 1 - weak consistency
ks3: N = 2, R = 1, W = 1 - weak consistency


# 172.17.0.3 - cas2