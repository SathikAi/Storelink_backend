
import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def check_db():
    try:
        connection = pymysql.connect(
            host='localhost',
            user='storelink_user',
            password='devpassword',
            database='storelink_dev',
            port=3307,
            cursorclass=pymysql.cursors.DictCursor
        )
        with connection.cursor() as cursor:
            print("\n--- Businesses ---")
            cursor.execute("SELECT uuid, business_name, logo_url, banner_url FROM businesses LIMIT 5")
            for row in cursor.fetchall():
                print(f"Name: {row['business_name']}, Logo: {row['logo_url']}, Banner: {row['banner_url']}")
            
            print("\n--- Products ---")
            cursor.execute("SELECT name, image_urls FROM products LIMIT 5")
            for row in cursor.fetchall():
                print(f"Name: {row['name']}, URLs: {row['image_urls']}")
                
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'connection' in locals():
            connection.close()

if __name__ == "__main__":
    check_db()
