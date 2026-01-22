import mysql.connector


conn = mysql.connector.connect(
    host="localhost",
    database="aqi"
    user="aqi_user",
    password="aqi_pass", 
)

print("✅ MySQL connection successful")
conn.close()
