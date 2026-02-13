import sys
import os
import secrets
import string

# Add the parent directory to sys.path so we can import 'app'
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.core.security import hash_password


def generate_password(length: int = 16) -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def seed_data():
    db = SessionLocal()
    try:
        print("Starting database seeding...")

        # 1. Create a Super Admin with a random password
        admin_phone = os.environ.get("ADMIN_PHONE", "9876543210")
        admin_password = os.environ.get("ADMIN_PASSWORD") or generate_password()

        existing_admin = db.query(User).filter(
            User.phone == admin_phone,
            User.deleted_at.is_(None),
        ).first()

        if not existing_admin:
            print("Creating Super Admin...")
            new_admin = User(
                full_name="System Administrator",
                phone=admin_phone,
                password_hash=hash_password(admin_password),
                role=UserRole.SUPER_ADMIN,
                is_active=True,
                is_verified=True,
            )
            db.add(new_admin)
            db.commit()
            print(f"Super Admin created: phone={admin_phone}")
            print(f"Generated password: {admin_password}")
            print("IMPORTANT: Change this password immediately after first login!")
        else:
            print("Super Admin already exists, skipping.")

        print("Seeding completed successfully!")

    except Exception as e:
        print(f"Error during seeding: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_data()
