import mysql.connector as connector
import mysql.connector.pooling as pooling
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import wait
import time

CONFIG = {
  'user': 'client',
  'password': 'poiu',
  'host': '127.0.0.1',
  'port': '6603',
  'database': 'db',
}

TOTAL = 100_000
SQL = "INSERT INTO posts (id, text) VALUES (%s, %s)"

def measure_time(func, name):
    start = time.time()
    func()
    end = time.time()
    print(name, ":", end - start)

def drop_table(conn):
    cur = conn.cursor()
    cur.execute("DELETE FROM posts")
    conn.commit()
    cur.close()

def insert(conn, cursor, i):
    try:
        cursor.execute(SQL, (i, f"Post {i}"))
        conn.commit()
    except Exception as e:
        print(e)

def insert_and_close(conn, i):
    cursor = conn.cursor()
    insert(conn, cursor, i)
    cursor.close()
    conn.close()

## SYNC INSERT OF 100_000 entries
def run_sync_and_measure():
    conn = connector.connect(**CONFIG)
    drop_table(conn)
    measure_time(lambda: run_sync(conn), "sync")
    conn.close()

def run_sync(conn):
    cursor = conn.cursor()
    for i in range(TOTAL):
        insert(conn, cursor, i)
    cursor.close()

## ASYNC INSERT OF 100_000 entries
def run_async_and_measure(n_threads):
    conn = connector.connect(**CONFIG)
    drop_table(conn)
    conn.close()

    measure_time(lambda: run_async(n_threads), f"async {n_threads}")

def run_async(n_threads):
    with ThreadPoolExecutor(max_workers=n_threads) as executor:
        for i in range(0, TOTAL, n_threads):
            futures = []    
            for j in range(i, i+n_threads):
                conn = connector.connect(**CONFIG)
                futures.append(executor.submit(insert_and_close, conn, j))
            wait(futures)

# ASYNC WITH CONNECTION POOL
def run_async_with_pool(n_threads):
    pool = pooling.MySQLConnectionPool(pool_size = min(n_threads, 32),**CONFIG)
    with ThreadPoolExecutor(max_workers=n_threads) as executor:
        for i in range(0, TOTAL, n_threads):
            futures = []  
            for j in range(i, i+n_threads):
                conn = pool.get_connection()
                executor.submit(insert_and_close, conn, j)
            wait(futures)

def run_async_with_pool_and_measure(n_threads):
    conn = connector.connect(**CONFIG)
    drop_table(conn)
    conn.close()

    measure_time(lambda: run_async_with_pool(n_threads), f"async & pool {n_threads}")

if __name__ == "__main__":
    run_sync_and_measure()

    run_async_and_measure(20) # 
    run_async_and_measure(50) # 
    run_async_and_measure(100) #


    run_async_with_pool_and_measure(20) # 186.4451675415039
    run_async_with_pool_and_measure(32) #


# async 20 : 821.3850049972534
# async 50 : 814.341564655304
# async 100 : 946.5336458683014      
# sync : 484.79401683807373
# async & pool 20 : 606.6413397789001