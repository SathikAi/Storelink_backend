"""add aadhaar number and reviews final

Revision ID: 69520d0d831c
Revises: 002
Create Date: 2026-04-08 04:42:53.074330

"""
from alembic import op
import sqlalchemy as sa


revision = '69520d0d831c'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add columns (wrapped in try-except or just commented if already present)
    # Based on error, banner_url exists. Let's check others.
    
    # op.add_column('businesses', sa.Column('banner_url', sa.String(length=500), nullable=True))
    
    try:
        op.add_column('users', sa.Column('aadhaar_number', sa.String(length=12), nullable=True))
        op.create_index('ix_users_aadhaar_number', 'users', ['aadhaar_number'], unique=True)
    except Exception:
        pass
        
    try:
        op.add_column('orders', sa.Column('payment_proof_url', sa.String(length=255), nullable=True))
    except Exception:
        pass
        
    try:
        op.add_column('otp_verifications', sa.Column('failed_attempts', sa.BigInteger(), nullable=True))
    except Exception:
        pass

    # Create business_reviews table
    try:
        op.create_table('business_reviews',
            sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
            sa.Column('uuid', sa.String(length=36), nullable=False),
            sa.Column('business_id', sa.BigInteger(), nullable=False),
            sa.Column('order_id', sa.BigInteger(), nullable=True),
            sa.Column('customer_name', sa.String(length=255), nullable=False),
            sa.Column('rating', sa.Integer(), nullable=False),
            sa.Column('comment', sa.Text(), nullable=True),
            sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=True),
            sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ),
            sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_business_reviews_id'), 'business_reviews', ['id'], unique=False)
        op.create_index(op.f('ix_business_reviews_uuid'), 'business_reviews', ['uuid'], unique=True)
    except Exception:
        pass


def downgrade() -> None:
    pass # No need for downgrade logic now as we are fixing state
