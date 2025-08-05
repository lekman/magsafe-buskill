# Task Nag - Workflow Checkpoint Command

Please help me ensure we're following the task workflow properly by checking our current state and progress.

## Step 1: Review PRD-Parse Workflow
- Read the `.claude/commands/prd-parse.md` file to understand the complete workflow
- Verify we're following all steps, particularly:
  - Complexity analysis has been performed
  - Subtasks have been properly broken down for complex tasks
  - User confirmation was obtained before starting implementation

## Step 2: Check Current Task State
Run the following to understand our current position:
- `taskmaster list` - View all tasks and their current status
- `taskmaster current` - Show the current active task
- If no current task, check if we need to run `taskmaster next`

## Step 3: Verify Complexity Breakdown
If we haven't already:
- Check if `taskmaster analyze-complexity --research --threshold=5` was run
- Review `taskmaster complexity-report` output
- Ensure high-complexity tasks (score > 5) have been broken into subtasks
- If breakdown is missing, run the complexity analysis now

## Step 4: Quality Check Current Task
If we're currently working on a task:

### For Implementation Tasks:
- Is the code following project conventions?
- Are error cases being handled?
- Is the implementation matching the task requirements?
- Are comments and documentation included?

### For Test Tasks:
- Are tests comprehensive (happy path + edge cases)?
- Do tests follow the testing framework conventions?
- Is test coverage adequate?

### For Documentation Tasks:
- Is documentation clear and complete?
- Are examples included where appropriate?
- Does it follow the project's documentation standards?

### For DevOps/CI Tasks:
- Are scripts tested locally?
- Are environment variables documented?
- Is the configuration following security best practices?

**Note**: Skip specific QA operations if they're scheduled as separate dedicated tasks later in the workflow.

## Step 5: Update Task Status
Based on the quality check:
- If task needs more work: Keep status as `in-progress`
- If ready for review: `taskmaster set-status --id={task-id} --status=review`
- For subtasks: Update each subtask status individually

Show the user:
- Current task progress
- What's been completed
- What still needs work
- Any concerns or blockers

## Step 6: Get User Confirmation
Ask the user:
- "Is the current task implementation complete?"
- "Any feedback or changes needed?"
- If changes needed, implement them before proceeding

## Step 7: Close Task and Move Forward
If user confirms task is complete:
1. Close current task: `taskmaster set-status --id={task-id} --status=done`
2. Close all related subtasks: `taskmaster set-status --id={subtask-id} --status=done`
3. Sync progress: `taskmaster sync-readme`
4. Move to next task: `taskmaster next`
5. Report the new current task to user

## Step 8: Check Overall Progress
- Show total tasks completed vs remaining
- Estimate time to completion based on current pace
- Check if we're still aligned with the original implementation plan

If all tasks are complete, remind user to run `/project:pr` to create the pull request.

Please execute these steps now to ensure we're on track with the task workflow.