"""add_missing_columns: business banner_url, profile_image_urls; product image_urls

Revision ID: a1b2c3d4e5f6
Revises: 8e97915ad4d0
Create Date: 2026-04-09 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = 'a1b2c3d4e5f6'
down_revision = '8e97915ad4d0'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # businesses: add banner_url and profile_image_urls (was commented-out in prev migration)
    op.add_column('businesses', sa.Column('banner_url', sa.String(500), nullable=True))
    op.add_column('businesses', sa.Column('profile_image_urls', sa.JSON(), nullable=True))

    # products: add image_urls JSON column (image_url kept for single-image compat)
    # Only add if it doesn't already exist (prev migration may have added it)
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    product_cols = [c['name'] for c in inspector.get_columns('products')]
    if 'image_urls' not in product_cols:
        op.add_column('products', sa.Column('image_urls', sa.JSON(), nullable=True))
    if 'image_url' not in product_cols:
        op.add_column('products', sa.Column('image_url', sa.String(500), nullable=True))


def downgrade() -> None:
    op.drop_column('businesses', 'profile_image_urls')
    op.drop_column('businesses', 'banner_url')
    # Leave products columns intact on downgrade to avoid data loss
