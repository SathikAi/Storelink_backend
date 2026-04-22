"""add last_login to users

Revision ID: b3c4d5e6f7a8
Revises: a1b2c3d4e5f6
Create Date: 2026-04-15
"""
from alembic import op
import sqlalchemy as sa

revision = 'b3c4d5e6f7a8'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('last_login', sa.TIMESTAMP(), nullable=True))


def downgrade():
    op.drop_column('users', 'last_login')
