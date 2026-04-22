"""Initial migration

Revision ID: 001
Revises:
Create Date: 2026-01-10 23:17:44

"""
from alembic import op
import sqlalchemy as sa

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('users',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('phone', sa.String(length=15), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('password_hash', sa.String(length=255), nullable=False),
        sa.Column('full_name', sa.String(length=255), nullable=False),
        sa.Column('role', sa.Enum('SUPER_ADMIN', 'BUSINESS_OWNER', name='userrole'), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=False)
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_phone'), 'users', ['phone'], unique=False)
    op.create_index(op.f('ix_users_role'), 'users', ['role'], unique=False)
    op.create_index(op.f('ix_users_uuid'), 'users', ['uuid'], unique=False)
    op.create_index(op.f('ix_users_uuid_unique'), 'users', ['uuid'], unique=True)
    op.create_index(op.f('ix_users_email_unique'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_phone_unique'), 'users', ['phone'], unique=True)

    op.create_table('businesses',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('owner_id', sa.BigInteger(), nullable=False),
        sa.Column('business_name', sa.String(length=255), nullable=False),
        sa.Column('business_type', sa.String(length=100), nullable=True),
        sa.Column('phone', sa.String(length=15), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('state', sa.String(length=100), nullable=True),
        sa.Column('pincode', sa.String(length=10), nullable=True),
        sa.Column('gstin', sa.String(length=15), nullable=True),
        sa.Column('logo_url', sa.String(length=500), nullable=True),
        sa.Column('plan', sa.Enum('FREE', 'PAID', name='businessplan'), nullable=True),
        sa.Column('plan_expiry_date', sa.Date(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['owner_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_businesses_id'), 'businesses', ['id'], unique=False)
    op.create_index(op.f('ix_businesses_is_active'), 'businesses', ['is_active'], unique=False)
    op.create_index(op.f('ix_businesses_owner_id'), 'businesses', ['owner_id'], unique=False)
    op.create_index(op.f('ix_businesses_plan'), 'businesses', ['plan'], unique=False)
    op.create_index(op.f('ix_businesses_uuid'), 'businesses', ['uuid'], unique=False)
    op.create_index(op.f('ix_businesses_uuid_unique'), 'businesses', ['uuid'], unique=True)

    op.create_table('otp_verifications',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('phone', sa.String(length=15), nullable=False),
        sa.Column('otp_code', sa.String(length=6), nullable=False),
        sa.Column('purpose', sa.Enum('LOGIN', 'REGISTRATION', 'PASSWORD_RESET', name='otppurpose'), nullable=False),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('expires_at', sa.TIMESTAMP(), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_phone_purpose', 'otp_verifications', ['phone', 'purpose'], unique=False)
    op.create_index(op.f('ix_otp_verifications_expires_at'), 'otp_verifications', ['expires_at'], unique=False)
    op.create_index(op.f('ix_otp_verifications_id'), 'otp_verifications', ['id'], unique=False)

    op.create_table('categories',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('business_id', 'name', 'deleted_at', name='unique_category_per_business')
    )
    op.create_index(op.f('ix_categories_business_id'), 'categories', ['business_id'], unique=False)
    op.create_index(op.f('ix_categories_id'), 'categories', ['id'], unique=False)
    op.create_index(op.f('ix_categories_is_active'), 'categories', ['is_active'], unique=False)
    op.create_index(op.f('ix_categories_uuid_unique'), 'categories', ['uuid'], unique=True)

    op.create_table('customers',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('phone', sa.String(length=15), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('city', sa.String(length=100), nullable=True),
        sa.Column('state', sa.String(length=100), nullable=True),
        sa.Column('pincode', sa.String(length=10), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('business_id', 'phone', 'deleted_at', name='unique_customer_phone_per_business')
    )
    op.create_index(op.f('ix_customers_business_id'), 'customers', ['business_id'], unique=False)
    op.create_index(op.f('ix_customers_id'), 'customers', ['id'], unique=False)
    op.create_index(op.f('ix_customers_is_active'), 'customers', ['is_active'], unique=False)
    op.create_index(op.f('ix_customers_phone'), 'customers', ['phone'], unique=False)
    op.create_index(op.f('ix_customers_uuid_unique'), 'customers', ['uuid'], unique=True)

    op.create_table('plan_limits',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('max_products', sa.Integer(), nullable=True),
        sa.Column('max_orders', sa.Integer(), nullable=True),
        sa.Column('max_customers', sa.Integer(), nullable=True),
        sa.Column('features', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('business_id')
    )
    op.create_index(op.f('ix_plan_limits_business_id'), 'plan_limits', ['business_id'], unique=False)
    op.create_index(op.f('ix_plan_limits_id'), 'plan_limits', ['id'], unique=False)

    op.create_table('products',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('category_id', sa.BigInteger(), nullable=True),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('sku', sa.String(length=100), nullable=True),
        sa.Column('price', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('cost_price', sa.DECIMAL(precision=10, scale=2), nullable=True),
        sa.Column('stock_quantity', sa.Integer(), nullable=True),
        sa.Column('unit', sa.String(length=50), nullable=True),
        sa.Column('image_url', sa.String(length=500), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['category_id'], ['categories.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_products_business_id'), 'products', ['business_id'], unique=False)
    op.create_index(op.f('ix_products_category_id'), 'products', ['category_id'], unique=False)
    op.create_index(op.f('ix_products_id'), 'products', ['id'], unique=False)
    op.create_index(op.f('ix_products_is_active'), 'products', ['is_active'], unique=False)
    op.create_index(op.f('ix_products_sku'), 'products', ['sku'], unique=False)
    op.create_index(op.f('ix_products_uuid_unique'), 'products', ['uuid'], unique=True)

    op.create_table('orders',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('uuid', sa.String(length=36), nullable=False),
        sa.Column('order_number', sa.String(length=50), nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('customer_id', sa.BigInteger(), nullable=True),
        sa.Column('order_date', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('status', sa.Enum('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', name='orderstatus'), nullable=True),
        sa.Column('subtotal', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('tax_amount', sa.DECIMAL(precision=10, scale=2), nullable=True),
        sa.Column('discount_amount', sa.DECIMAL(precision=10, scale=2), nullable=True),
        sa.Column('total_amount', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('payment_method', sa.String(length=50), nullable=True),
        sa.Column('payment_status', sa.Enum('PENDING', 'PAID', 'FAILED', 'REFUNDED', name='paymentstatus'), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.Column('deleted_at', sa.TIMESTAMP(), nullable=True),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('order_number')
    )
    op.create_index(op.f('ix_orders_business_id'), 'orders', ['business_id'], unique=False)
    op.create_index(op.f('ix_orders_customer_id'), 'orders', ['customer_id'], unique=False)
    op.create_index(op.f('ix_orders_id'), 'orders', ['id'], unique=False)
    op.create_index(op.f('ix_orders_order_date'), 'orders', ['order_date'], unique=False)
    op.create_index(op.f('ix_orders_status'), 'orders', ['status'], unique=False)
    op.create_index(op.f('ix_orders_uuid'), 'orders', ['uuid'], unique=False)
    op.create_index(op.f('ix_orders_uuid_unique'), 'orders', ['uuid'], unique=True)

    op.create_table('order_items',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('order_id', sa.BigInteger(), nullable=False),
        sa.Column('product_id', sa.BigInteger(), nullable=True),
        sa.Column('product_name', sa.String(length=255), nullable=False),
        sa.Column('product_sku', sa.String(length=100), nullable=True),
        sa.Column('quantity', sa.BigInteger(), nullable=False),
        sa.Column('unit_price', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('total_price', sa.DECIMAL(precision=10, scale=2), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_order_items_id'), 'order_items', ['id'], unique=False)
    op.create_index(op.f('ix_order_items_order_id'), 'order_items', ['order_id'], unique=False)
    op.create_index(op.f('ix_order_items_product_id'), 'order_items', ['product_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_order_items_product_id'), table_name='order_items')
    op.drop_index(op.f('ix_order_items_order_id'), table_name='order_items')
    op.drop_index(op.f('ix_order_items_id'), table_name='order_items')
    op.drop_table('order_items')

    op.drop_index(op.f('ix_orders_uuid_unique'), table_name='orders')
    op.drop_index(op.f('ix_orders_uuid'), table_name='orders')
    op.drop_index(op.f('ix_orders_status'), table_name='orders')
    op.drop_index(op.f('ix_orders_order_date'), table_name='orders')
    op.drop_index(op.f('ix_orders_id'), table_name='orders')
    op.drop_index(op.f('ix_orders_customer_id'), table_name='orders')
    op.drop_index(op.f('ix_orders_business_id'), table_name='orders')
    op.drop_table('orders')

    op.drop_index(op.f('ix_products_uuid_unique'), table_name='products')
    op.drop_index(op.f('ix_products_sku'), table_name='products')
    op.drop_index(op.f('ix_products_is_active'), table_name='products')
    op.drop_index(op.f('ix_products_id'), table_name='products')
    op.drop_index(op.f('ix_products_category_id'), table_name='products')
    op.drop_index(op.f('ix_products_business_id'), table_name='products')
    op.drop_table('products')

    op.drop_index(op.f('ix_plan_limits_id'), table_name='plan_limits')
    op.drop_index(op.f('ix_plan_limits_business_id'), table_name='plan_limits')
    op.drop_table('plan_limits')

    op.drop_index(op.f('ix_customers_uuid_unique'), table_name='customers')
    op.drop_index(op.f('ix_customers_phone'), table_name='customers')
    op.drop_index(op.f('ix_customers_is_active'), table_name='customers')
    op.drop_index(op.f('ix_customers_id'), table_name='customers')
    op.drop_index(op.f('ix_customers_business_id'), table_name='customers')
    op.drop_table('customers')

    op.drop_index(op.f('ix_categories_uuid_unique'), table_name='categories')
    op.drop_index(op.f('ix_categories_is_active'), table_name='categories')
    op.drop_index(op.f('ix_categories_id'), table_name='categories')
    op.drop_index(op.f('ix_categories_business_id'), table_name='categories')
    op.drop_table('categories')

    op.drop_index(op.f('ix_otp_verifications_id'), table_name='otp_verifications')
    op.drop_index(op.f('ix_otp_verifications_expires_at'), table_name='otp_verifications')
    op.drop_index('idx_phone_purpose', table_name='otp_verifications')
    op.drop_table('otp_verifications')

    op.drop_index(op.f('ix_businesses_uuid_unique'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_uuid'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_plan'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_owner_id'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_is_active'), table_name='businesses')
    op.drop_index(op.f('ix_businesses_id'), table_name='businesses')
    op.drop_table('businesses')

    op.drop_index(op.f('ix_users_phone_unique'), table_name='users')
    op.drop_index(op.f('ix_users_email_unique'), table_name='users')
    op.drop_index(op.f('ix_users_uuid_unique'), table_name='users')
    op.drop_index(op.f('ix_users_uuid'), table_name='users')
    op.drop_index(op.f('ix_users_role'), table_name='users')
    op.drop_index(op.f('ix_users_phone'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_table('users')
