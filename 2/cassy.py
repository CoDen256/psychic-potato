import time
from cassandra.cluster import Cluster
from cassandra import ConsistencyLevel
from cassandra.query import SimpleStatement

def measure_time(func):
    start = time.time()
    func()
    end = time.time()
    print(end - start)

def insert_entries(session):
    for i in range(100_000):
        query = SimpleStatement("INSERT INTO posts (id, text) VALUES (%s, %s)", consistency_level=ConsistencyLevel.ONE)
        session.execute(query, (i, f"Post {i}"))

if __name__ == "__main__":
    cluster = Cluster(['0.0.0.0'],port=9042)
    session = cluster.connect()
    
    session.execute("CREATE KEYSPACE IF NOT EXISTS ks WITH REPLICATION = {'class':'SimpleStrategy', 'replication_factor':1}")
    session.execute("CREATE TABLE IF NOT EXISTS ks.posts (id int PRIMARY KEY, text text);")

    session.execute("USE ks")
    session.execute("TRUNCATE posts")

    measure_time(lambda: insert_entries(session)) # 154.49652361869812