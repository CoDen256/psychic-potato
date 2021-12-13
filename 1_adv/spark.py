from pyspark.sql.functions import *
from pyspark.sql.types import Row
class WikipediaArticle:
    def __init__(self, title, text):
        self.title = title
        self.text = text
def parse(line):
    subs = "</title><text>"
    i = line.index(subs)
    title = line[14:i]
    text  = line[i + len(subs): len(line)-16]
    return WikipediaArticle(title, text)
def convert(line): 
    mapped = parse(line.value)
    return Row(title = mapped.title, text = mapped.text)

langs = ["JavaScript", "Java", "PHP", "Python", "C#", "C++", "Ruby", "CSS", "Objective-C", "Perl", "Scala", "Haskell", "MATLAB", "Clojure", "Groovy"]

df = spark.read.text("wikipedia.dat")
df.rdd \
    .map(convert) \
    .zipWithIndex() \
    .map(lambda r: Row(id=r[1], text=r[0].text)) \
    .toDF() \
    .select(explode(split(col("text"), "[^a-zA-Z-+#]")).alias("lang"), col("id")) \
    .filter(col("lang").isin(langs)) \
    .groupBy("lang") \
    .agg(count("*").alias("total"), countDistinct("lang", "id").alias("articles")) \
    .show()