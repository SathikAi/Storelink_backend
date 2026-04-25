"""add affiliate and referrals tables

Revision ID: c1d2e3f4a5b6
Revises: 4ce72fcb33d4
Create Date: 2026-04-25
"""
from alembic import op
import sqlalchemy as sa

revision = 'c1d2e3f4a5b6'
down_revision = '4ce72fcb33d4'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'affiliates',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('business_id', sa.BigInteger(), nullable=False),
        sa.Column('referral_code', sa.String(12), nullable=False),
        sa.Column('reward_days', sa.Integer(), nullable=False, server_default='30'),
        sa.Column('total_referrals', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('rewarded_referrals', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('business_id'),
        sa.UniqueConstraint('referral_code'),
    )
    op.create_index('ix_affiliates_business_id', 'affiliates', ['business_id'])
    op.create_index('ix_affiliates_referral_code', 'affiliates', ['referral_code'])

    op.create_table(
        'referrals',
        sa.Column('id', sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column('affiliate_id', sa.BigInteger(), nullable=False),
        sa.Column('referred_business_id', sa.BigInteger(), nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'REWARDED', name='referralstatus'),
                  nullable=False, server_default='PENDING'),
        sa.Column('created_at', sa.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('rewarded_at', sa.TIMESTAMP(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['affiliate_id'], ['affiliates.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['referred_business_id'], ['businesses.id'], ondelete='CASCADE'),
        sa.UniqueConstraint('referred_business_id'),
    )
    op.create_index('ix_referrals_affiliate_id', 'referrals', ['affiliate_id'])
    op.create_index('ix_referrals_referred_business_id', 'referrals', ['referred_business_id'])
    op.create_index('ix_referrals_status', 'referrals', ['status'])


def downgrade():
    op.drop_table('referrals')
    op.drop_index('ix_affiliates_referral_code', 'affiliates')
    op.drop_index('ix_affiliates_business_id', 'affiliates')
    op.drop_table('affiliates')
    op.execute("DROP TYPE IF EXISTS referralstatus")
