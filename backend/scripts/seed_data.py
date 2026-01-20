import sys
import os
import asyncio
from datetime import datetime

# Add the parent directory to sys.path so we can import 'app'
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal, engine
from app.models import user, business, category
from app.core.security import get_password_hash

async def seed_data():
    db = SessionLocal()
    try:
        print("🌱 Starting database seeding...")

        # 1. Create a Super Admin
        admin_phone = "9876543210"
        existing_admin = db.query(user.User).filter(user.User.phone == admin_phone).first()
        
        if not existing_admin:
            print("👤 Creating Super Admin...")
            new_admin = user.User(
                full_name="System Administrator",
                phone=admin_phone,
                hashed_password=get_password_hash("Admin@123"), # Change this in production!
                role="SUPER_ADMIN",
                is_active=True,
                is_verified=True
            )
            db.add(new_admin)
            db.flush() # Get the ID
            print(f"✅ Super Admin created: {admin_phone}")
        else:
            print("ℹ️ Super Admin already exists.")
            new_admin = existing_admin

        # 2. Create default categories
        categories = ["Electronics", "Groceries", "Clothing", "Furniture", "Pharmacy", "Stationery"]
        for cat_name in categories:
            existing_cat = db.query(category.Category).filter(category.Category.name == cat_name).first()
            if not existing_cat:
                new_cat = category.Category(
                    name=cat_name,
                    description=f"Default {cat_name} category",
                    is_active=True
                )
                db.add(new_cat)
                print(f"📂 Category added: {cat_name}")

        db.commit()
        print("✨ Seeding completed successfully!")

    except Exception as e:
        print(f"❌ Error during seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(seed_data())
