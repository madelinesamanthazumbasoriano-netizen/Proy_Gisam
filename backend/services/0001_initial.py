"""Initial GISAM relational schema."""

from alembic import op
import sqlalchemy as sa

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "users",
        sa.Column("id", sa.String(128), primary_key=True),
        sa.Column("display_name", sa.String(80), nullable=False),
        sa.Column("bio", sa.String(500), nullable=False),
        sa.Column("avatar", sa.String(120), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "tree_state",
        sa.Column("user_id", sa.String(128), sa.ForeignKey("users.id"), primary_key=True),
        sa.Column("level", sa.Integer(), nullable=False),
        sa.Column("xp", sa.Integer(), nullable=False),
        sa.Column("xp_required", sa.Integer(), nullable=False),
        sa.Column("water", sa.Integer(), nullable=False),
        sa.Column("health", sa.Integer(), nullable=False),
        sa.Column("happiness", sa.Integer(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_table(
        "missions",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.String(128), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("title", sa.String(160), nullable=False),
        sa.Column("xp_reward", sa.Integer(), nullable=False),
        sa.Column("completed", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_missions_user_id", "missions", ["user_id"])
    op.create_table(
        "friendships",
        sa.Column("user_id", sa.String(128), sa.ForeignKey("users.id"), primary_key=True),
        sa.Column("friend_id", sa.String(128), sa.ForeignKey("users.id"), primary_key=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("user_id", "friend_id", name="uq_friendship"),
    )


def downgrade():
    op.drop_table("friendships")
    op.drop_index("ix_missions_user_id", table_name="missions")
    op.drop_table("missions")
    op.drop_table("tree_state")
    op.drop_table("users")
