# PRD Parse and Task Management Command

Please help me parse the PRD and set up a task workflow using the taskmaster CLI by following these steps:

## Step 1: Analyze Requirements and PRD
- Get the current git branch name using `git branch --show-current`
- Extract the Jira ticket (PLATSD-XXXXX) from the branch name
- Read `requirement.md` from the repository root
- Read the corresponding PRD file `prd.{jira-ticket}.md` from the repository root
  - For example: if on branch `feature/PLATSD-12345-feature`, read `prd.PLATSD-12345.md`
- Analyze both documents to understand the scope and complexity

## Step 2: Determine Complexity and Task Count
Based on the analysis, estimate the appropriate number of subtasks considering:
- **SDLC phases**: Planning, Implementation, Testing, Documentation, DevOps/CICD
- **Test-Driven Development**: Include tasks for writing tests before implementation
- **Complexity indicators**:
  - Simple changes (typos, config): 3-5 tasks
  - Medium features: 5-10 tasks
  - Complex features: 10-15 tasks
  - Major architectural changes: 15+ tasks

Example task breakdown:
- Prepare repository and dependencies
- Write unit tests for new functionality
- Implement core feature changes
- Add integration tests
- Update CI/CD pipelines
- Update documentation
- Performance testing and optimization
- Security review

## Step 3: Parse PRD with Taskmaster
From the repository root, execute:
```bash
taskmaster parse-prd --input=prd.{jira-ticket}.md --num-tasks={estimated-number}
```
Wait for the command to complete and generate tasks in the `.taskmaster` folder.

### Cleanup after parsing
Once the command completes, clean up unnecessary files:
- Delete `.env.example` if it was created: `rm -f .env.example`
- Report to user that cleanup is complete

## Step 4: Review and Refine Tasks
- List all created tasks in the `.taskmaster` folder
- Analyze each task for:
  - Clarity and completeness
  - Proper sequencing
  - Appropriate scope
- Present findings to the user and ask for feedback
- For tasks that should be:
  - Done later: `taskmaster set-status --id={id} --status=deferred`
  - Not done at all: `taskmaster set-status --id={id} --status=cancelled`
- Refine task descriptions based on user feedback

## Step 5: Analyze Task Complexity
- Run complexity analysis: `taskmaster analyze-complexity --research --threshold=5`
- This will break down high-complexity tasks into subtasks
- Show complexity report: `taskmaster complexity-report`
- Explain to the user:
  - Which tasks were expanded
  - Current complexity scores
  - Recommended approach for complex tasks

## Step 6: Implementation Summary
Present a clear summary:
- Total number of tasks
- Estimated timeline
- Task sequence and dependencies
- Key milestones
- Testing strategy
- Documentation updates needed

Ask user: "Ready to start implementation? Any adjustments needed?"
Refine based on feedback.

## Step 7: Execute Tasks
Once user confirms:
- Start with: `taskmaster next`
- For each task:
  - Implement the required changes
  - Update status: `taskmaster set-status --id={id} --status=in-progress`
  - Once complete: `taskmaster set-status --id={id} --status=done`
  - Sync README: `taskmaster sync-readme`
  - Report progress to user
  - Ask for feedback before moving to next task
  - If review needed: `taskmaster set-status --id={id} --status=review`

**Important**: Never commit or push files. All git operations should be done by the user.

## Step 8: Update CLAUDE.md
Ensure CLAUDE.md includes:
- Information about the taskmaster workflow
- Note that Claude should never commit or push files
- Current project status and progress
- Any project-specific conventions discovered

Update CLAUDE.md as needed throughout the process.

## Step 9: Complete and Create PR
When all tasks show status `done`:
- Confirm with user: "All tasks complete. Ready to create a pull request?"
- If confirmed, run: `/project:pr`
- This will generate the PR description including all completed work

Please execute these steps now, starting with Step 1.