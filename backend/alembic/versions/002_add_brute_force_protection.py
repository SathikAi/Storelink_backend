"""Add brute force protection fields to user

Revision ID: 002
Revises: 001
Create Date: 2026-01-17 12:50:00

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('failed_login_attempts', sa.BigInteger(), nullable=True, server_default='0'))
    op.add_column('users', sa.Column('locked_until', sa.TIMESTAMP(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'locked_until')
    op.drop_column('users', 'failed_login_attempts')
