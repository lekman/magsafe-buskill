# PRD Preparation Command

Please help me prepare a Product Requirements Document (PRD) by following these steps:

1. **Get the Jira ticket number**:

   - Check the current git branch name using `git branch --show-current`
   - Extract the Jira ticket (PLATSD-XXXXX) from the branch name
   - Branch format is: `{type}/PLATSD-{number}-{feature-name}`

2. **Read the requirement**:

   - Read the contents of `requirement.md` from the repository root
   - This contains the Jira requirement that needs to be analyzed

3. **Read the PRD template**:

   - Read the PRD template from `.claude/templates/prd.md`
   - This will be the structure to follow for the new PRD

4. **Analyze and create the PRD**:

   - Analyze the requirement from `requirement.md`
   - Create a new PRD document following the template structure
   - Fill in all sections based on the requirement analysis
   - Ensure the PRD is comprehensive and addresses all aspects of the requirement

5. **Save the PRD**:
   - Save the completed PRD as `prd.{jira-ticket}.md` in the repository root
   - For example: if the ticket is PLATSD-12345, save as `prd.PLATSD-12345.md`

Please execute these steps now.
