# Technical Documentation Guidelines

This page outlines best practices for writing supporting documentation for stakeholders. The goal is to create documentation that is accessible, actionable, and useful for diverse team members, including those who do not use English as their first language.

## Formal Documentation vs Technical Documentation

In our team, documentation is broadly categorised into three types:

### Formal Documentation

- **Purpose**: Formal documents are required for regulatory compliance under documented, legal standards.
- **Structure**: Must follow our standard document structures.
- **Storage**: Stored and managed in the eQMS system.
- **Content Sources**: Formal documents are generated using data from Jira, including:
  - **Epics**
  - **Stories**
  - **Xray Tests**
- **Required Documents**
  - Regulatory Impact Determination (RID)
  - Functional Risk Assessment (FRA)
  - User Requirements Specification (URS)
  - Functional Requirements Specification (FRS)
  - Solution Blueprint
  - Validation Plan and Test Approach
  - Installation Qualification (IQ)/Operational Qualification (OQ) Protocol
  - IQ/OQ Test Scripts
  - Test Execution Results
  - Traceability Matrix

### Blueprints

- Purpose: Blueprints document the design and technical implementation of individual components within a system. Together, they serve as the foundation for creating Solution Blueprint documents for regulatory purposes.
- Scope: Each blueprint covers one specific component of the system, such as a service, API, or module.
- Audience: Designed for architects, engineers, and other technical stakeholders who need to understand a component's design and functionality.
- Format: Published in Confluence as modular segments, using a standardised template.
- Examples: API Blueprint, Kafka Topic Blueprint, Lambda Handler Blueprint.

Blueprints provide a structured way to document components while maintaining consistency across the system. They are also used as building blocks for generating higher-level formal documents.

### Technical Documentation

- **Purpose**: Technical documentation explains and aligns on specific topics related to services and practices, tailored for a specific role or task.
- **Audience**: Written to address the needs of integration engineers, operations specialists, architects, or other technical stakeholders.
- **Format**: Primarily published in Confluence and is less formal than regulatory-compliant documents.
- **Examples**: Integration Handler Guides, Platform Deployment Guides, Best Practices for PDR.

This document focuses on **technical documentation**, providing guidelines to ensure it is effective and user-friendly for our stakeholders.

## Documentation as Code

Documentation as Code is a methodology that applies the principles of software development to the creation of documentation. It is a way to manage documentation that treats it as an integral part of the development process, rather than as an afterthought.

Your documentation is stored in a repository, and you can use the same tools and processes that you use for code to manage it. This includes version control, continuous integration, and automated testing.

The automation workflow will publish the markdown files as Confluence pages using a GitHub workflow Action.

## Key Principles for Technical Documentation

1. **Know Your Audience**
   - Clearly identify the target audience for each document. For example:
     - Integration Engineers need technical depth and walkthroughs.
     - Operations Specialists need actionable troubleshooting steps.
     - Architects need system-level overviews and design considerations.
   - Tailor the content to the reader’s role and level of technical knowledge.
2. **Use Accessible Language**
   - Write in simple, straightforward English to accommodate team members whose first language is not English.
   - Write short, simple sentences. Avoid unnecessary business jargon or abstract terms.
   - Use examples to clarify complex ideas.
     - Example: Instead of "Ensure handlers are compatible with organisational standards," write "Use the AVRO schema required for PDR compatibility."
   - Avoid idioms, cultural references, or complex language that may be unclear to non-native speakers.
   - Explain abbreviations and acronyms the first time they appear. For example:
     - "PDR (Perimeter Data Router) is our central integration platform."
   - Maintain consistency in terminology. Use the same term throughout the document to avoid confusion.
3. Include Visual Aids
   - Use diagrams, tables, or screenshots to support written instructions.
   - Highlight key information with bold text or callout boxes for better visibility.
4. **Structure for Clarity**
   - Follow this consistent structure across all documentation:
     - **Introduction**: A brief overview of the document's purpose and its relevance.
     - **Responsibilities**: Who the document is for and what they need to do.
     - **Step-by-Step Walkthroughs**: Clear instructions with links to additional resources.
     - **Subtopics**: Break down complex topics into smaller, linked Confluence pages.
     - **References**: Include links to related documentation, templates, or external resources.
5. **Order Information by Priority**
   - Start with a quick background for context, followed by responsibilities, and then detailed instructions.
   - For example:
     - Begin with: "The Perimeter Data Router (PDR) is a centralised hub for data exchange."
     - Follow with: "Integration Engineers are responsible for building and maintaining integration handlers."

## Best Practices for Writing Technical Documentation

1. **Be Action-Oriented**
   - Focus on actionable steps for the user. Use numbered lists for step-by-step instructions.
   - Example:
     - **Poor**: "Configure the handler for compatibility."
     - **Better**: "Open config.json and set the API_ENDPOINT field to the target URL."
2. **Use Consistent Formatting**
   - Follow the same format across pages:
     - Headings for sections (#, ##, ###).
     - Bullet points for lists.
     - Tables for comparisons or detailed configurations.
3. **Link to Resources**
   - Include links to related pages or external resources for deeper context. Examples:
     - Integration Handler Checklist
     - AWS CDK Deployment Guide
4. **Create FAQs**
   - Add a Frequently Asked Questions (FAQ) section to address common issues.
     - Example:
       - **Q:** How do I deploy an integration handler?
       - **A:** Follow the AWS CDK Deployment Guide.

### Example Structure

The following is a suggested example of technical documentation within a Confluence page:

1. **Title**: Integration Handler Development Guide
2. **Introduction**
   - "This page explains how to design, develop, and deploy integration handlers within the PDR platform. It is intended for Integration Engineers responsible for building and maintaining data integrations."
3. **Target Audience**
   - Integration Engineers.
4. **Quick Background**
   - "An integration handler processes and routes data between systems while adhering to PDR’s standards for messaging and security."
5. **Responsibilities**
   - Clearly define what the target audience is responsible for.
6. **Step-by-Step Walkthroughs**
   - Break down instructions into clear steps, with links to detailed guides:
     - "1. Write the handler in Node.js, Kotlin, or Python. [See Examples](https://untitled+.vscode-resource.vscode-cdn.net/Untitled-1)."
     - "2. Deploy the handler using AWS CDK. [See Deployment Guide](https://untitled+.vscode-resource.vscode-cdn.net/Untitled-1)."
7. **Best Practices**
   - List key practices, such as:
     - "Follow the AVRO schema for messaging."
     - "Ensure handlers are modular and reusable."
8. **FAQs**
   - Answer common questions in a concise format.
