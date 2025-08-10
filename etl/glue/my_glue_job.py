from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, when, round

#  Start a local Spark session
spark = SparkSession.builder \
    .appName("LocalETLTest") \
    .getOrCreate()

# 📁 Load CSV files from local 'data/' folder
bucket = "mydemobucket-2810"
base_path = f"s3://{bucket}/data/"

customer_df = spark.read.option("header", True).csv(base_path + "customer.csv")
account_df = spark.read.option("header", True).csv(base_path + "account.csv")
transaction_df = spark.read.option("header", True).csv(base_path + "transaction.csv")

# 🔁 Ensure join keys are strings
customer_df = customer_df.withColumn("customer_id", col("customer_id").cast("string"))
account_df = account_df.withColumn("customer_id", col("customer_id").cast("string")) \
                       .withColumn("account_id", col("account_id").cast("string"))
transaction_df = transaction_df.withColumn("account_id", col("account_id").cast("string"))

# 🔗 Join customer → account → transaction
cust_acc_df = customer_df.join(account_df, on="customer_id", how="inner")
final_df = cust_acc_df.join(transaction_df, on="account_id", how="inner")

# 🧪 1. Check for missing/null values
print("🔍 Null value count per column:")
null_counts = final_df.select([
    count(when(col(c).isNull(), c)).alias(c) for c in final_df.columns
])
null_counts.show(truncate=False)

# 🧾 2. Check for duplicate rows
print("🔍 Duplicate row count:")
duplicates = final_df.groupBy(final_df.columns).count().filter("count > 1")
duplicates.show(truncate=False)

# 🛠 3. Fill missing values (example: email)
final_df = final_df.fillna({"email": "unknown@example.com"})

# ➕ 4. Add derived column: amount in dollars
final_df = final_df.withColumn("amount_dollars", round(col("amount_cents") / 100, 2))

# 💾 5. Save to Parquet (output folder will be created)
final_df.coalesce(1) \
    .write \
    .mode("overwrite") \
    .option("header", True) \
    .csv("s3://mydemobucket-2810/output/cleaned_data_csv")


#  Stop Spark session
spark.stop()
