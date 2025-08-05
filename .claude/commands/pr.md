# PR Preparation Command

Please help me prepare a Pull Request description by following these steps:

1. **Get the Jira ticket number**:

   - Check the current git branch name using `git branch --show-current`
   - Extract the Jira ticket (PLATSD-XXXXX) from the branch name
   - Branch format is: `{type}/PLATSD-{number}-{feature-name}`
   - If not applicable, ignore as this is not a Jira ticket PR

2. **Read the PR template**:

   - Read the Pull Request template from `.github/pull_request_template.md`
   - This will be the structure to follow for the PR description

3. **Check for PRD and gather context**:

   - **First, check if a PRD exists**: Look for `docs/PRD.md`
   - **If PRD EXISTS** (typical for features):
     - Read `docs/REQUIREMENTS.md` from the docs folder
     - Read the PRD file `docs/PRD.md`
     - Use both as context for the PR description
   - **If NO PRD EXISTS** (common for patches, CVE fixes, minor corrections):

     - Skip reading REQUIREMENTS.md and PRD
     - Base the PR description solely on the commit history and changes
     - This is expected for quick patches and hotfixes

   - **Always get Commit History**:
     - Use `git log --oneline origin/main..HEAD` to see commits
     - Or `git log --pretty=format:"- %s" origin/main..HEAD` for a formatted list

4. **Analyze and create the PR description**:

   - Use the PR template structure
   - **If PRD exists**: Fill sections using REQUIREMENTS.md, PRD, and commit history
   - **If NO PRD**: Fill sections based on commit history and the actual code changes
   - Always include:
     - Summary of changes
     - Link to Jira ticket
     - Testing performed
     - Any breaking changes or migration notes
     - Checklist items from the template

5. **Save the PR description**:

   - Save the completed PR description as `pr.{jira-ticket}.md` in the repository root
   - For example: if the ticket is PLATSD-12345, save as `pr.PLATSD-12345.md`
   - This file can then be used when creating the actual PR on GitHub/GitLab

6. **Archive old PR documents**:
   - Look for other root repo documents named `pr.*` and move them to the `docs/archive` folder

Please execute these steps now.
