--Exercise one

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("tasks.id", ondelete="CASCADE"))
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    task = relationship("Task", back_populates="comments")
    user = relationship("User")

1. `Comment` should relate to `Task` and `User`.
2. Yes, `Task` should have a `comments` relationship.
3. Comments should be deleted automatically (`CASCADE`) when a task is deleted.

--Exercise two

1. `upgrade()` creates the `comments` table and applies schema changes.

2. `downgrade()` reverses the migration changes.

3. Downgrading deletes the `comments` table and its data.

Bonus:

CheckConstraint("content != ''", name="ck_comments_content_not_empty")

--Exercise three

team = Team(name="DevOps", description="Infrastructure team")

user = User(
    username="diana_ops",
    email="diana@example.com",
    full_name="Diana Ops",
    team=team
)

task1 = Task(title="Setup CI/CD", status="open", priority="high", user=user)
task2 = Task(title="Monitor servers", status="open", priority="medium", user=user)
task3 = Task(title="Clean logs", status="open", priority="low", user=user)

session.add(team)
session.commit()

print("Task count:", session.query(Task).count())

task1.status = "closed"
session.commit()

session.delete(task3)
session.commit()

print("Closed task:", task1.title)
print("Deleted task:", task3.title)

--Exercise four

1. The `estimated_hours` column is removed.

2. All data stored in that column is permanently lost.

--Exercise five

1. ORM simplifies database interaction using Python objects.

2. Migrations track and apply schema changes safely.

3. To undo a bad or broken migration.

4. `add()` stages changes; `commit()` saves them permanently.

5. Relationships simplify linked data access between tables.
