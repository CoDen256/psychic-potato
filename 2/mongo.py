from pymongo import MongoClient
import time
from pprint import pprint

def measure_time(func):
    start = time.time()
    func()
    end = time.time()
    print(end - start)

def insert_entries(collection):
    for i in range(10):
        sql = "INSERT INTO posts (id, text) VALUES (%s, %s)"
        collection.runSQLQuery(sql, (i, f"Post {i}"))

if __name__ == "__main__":
    client = MongoClient(host= '0.0.0.0' ,port=27017)

    # session.execute("CREATE KEYSPACE IF NOT EXISTS ks WITH REPLICATION = {'class':'SimpleStrategy', 'replication_factor':1}")
    # session.execute("CREATE TABLE IF NOT EXISTS ks.posts (id int PRIMARY KEY, text text);")

    # session.execute("USE ks")
    # session.execute("TRUNCATE posts")

    # measure_time(lambda: insert_entries(collection)) # 154.49652361869812