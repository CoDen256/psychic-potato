from pymongo import MongoClient
from pymongo.write_concern import WriteConcern
import time

def measure_time(func):
    start = time.time()
    func()
    end = time.time()
    print(end - start)

def insert_entries(collection):
    for i in range(100_000):
        collection.with_options(write_concern = WriteConcern(w=1, j=True)) \
                .insert_one({"id":i, "text": f"Post {i}"} )

if __name__ == "__main__":
    client = MongoClient(host= '0.0.0.0' ,port=27017)

    db = client.mydb
    posts = db.posts

    posts.delete_many({})

    measure_time(lambda: insert_entries(posts)) # 389.6377100944519