# Figma Setup and Integration Guide

## Table of Contents
1. [Creating a Figma Account](#creating-a-figma-account)
2. [Installing Figma on Mac](#installing-figma-on-mac)
3. [Using Figma AI](#using-figma-ai)
4. [Installing Figma MCP for Claude Integration](#installing-figma-mcp-for-claude-integration)

## Creating a Figma Account

### Step 1: Sign Up
1. Visit [figma.com](https://www.figma.com)
2. Click "Get started for free"
3. Choose sign-up method:
   - Google account (recommended for easy access)
   - Email and password
   - SAML SSO (for enterprise)

### Step 2: Choose Your Plan
- **Starter** (Free): Perfect for this project
  - 3 Figma files
  - Unlimited personal files
  - Mobile app access
- **Professional** ($15/month): For advanced features
  - Unlimited files
  - Version history
  - Team libraries

### Step 3: Initial Setup
1. Complete onboarding questions (can skip)
2. Create your first team or use "Drafts" for personal work
3. Name your workspace (e.g., "MagSafe Guard Design")

## Installing Figma on Mac

### Option 1: Desktop App (Recommended)
1. Visit [figma.com/downloads](https://www.figma.com/downloads)
2. Click "Download Figma Desktop App"
3. Open the downloaded `.dmg` file
4. Drag Figma to Applications folder
5. Launch from Applications or Spotlight

### Option 2: Homebrew Installation
```bash
brew install --cask figma
```

### Option 3: Web App
- No installation needed
- Visit [figma.com](https://www.figma.com) and log in
- Works in any modern browser (Chrome recommended)

### Desktop App Benefits
- Better performance
- Local font access
- Offline mode
- Native OS integration
- Multiple window support

## Using Figma AI

### Enabling Figma AI
1. **Access Requirements**:
   - Available on all plans (including free)
   - Must be enabled by workspace admin
   - Currently in beta (as of 2025)

2. **Enable AI Features**:
   - Go to Settings → AI
   - Toggle "Enable AI features"
   - Accept AI terms of service

### AI Features for Menu Bar Design

#### 1. **AI Text Generation**
- Select text layer
- Click AI icon or press `Cmd + K`
- Commands for menu bar app:
  ```
  "Generate menu items for a security app"
  "Create status messages for armed/disarmed states"
  "Write error messages for authentication failures"
  ```

#### 2. **AI Design Suggestions**
- Select frame or component
- Use AI panel to request:
  ```
  "Create a menu bar icon for security app"
  "Design armed/disarmed state indicators"
  "Generate color variations for status states"
  ```

#### 3. **Component Generation**
- Type in AI prompt:
  ```
  "Create macOS menu bar dropdown with 5 items"
  "Design authentication dialog for Touch ID"
  "Generate settings window with tabs"
  ```

#### 4. **Asset Creation**
- Use AI for quick assets:
  ```
  "16x16 shield icon for menu bar"
  "Power adapter connection indicator"
  "Warning triangle for alerts"
  ```

### Best Practices for Figma AI
1. Be specific about macOS design guidelines
2. Reference "menu bar" or "NSStatusItem" for context
3. Ask for "template images" for proper macOS tinting
4. Request @1x and @2x versions

## Installing Figma MCP for Claude Integration

### What is Figma MCP?
Model Context Protocol (MCP) allows Claude to directly interact with Figma designs, converting them to code.

### Prerequisites
1. Claude Desktop app installed
2. Node.js 18+ installed
3. Figma account with API access

### Step 1: Get Figma API Token
1. Log into Figma
2. Go to Settings → Account
3. Under "Personal Access Tokens", click "Create new token"
4. Name it "Claude MCP Integration"
5. Copy the token (save securely)

### Step 2: Install Figma MCP Server
```bash
# Install globally
npm install -g @figma/mcp-server

# Or clone and install locally
git clone https://github.com/figma/mcp-server
cd mcp-server
npm install
```

### Step 3: Configure Claude Desktop
1. Open Claude Desktop settings
2. Navigate to "Developer" → "Model Context Protocol"
3. Add new server configuration:

```json
{
  "figma": {
    "command": "node",
    "args": ["/usr/local/lib/node_modules/@figma/mcp-server/dist/index.js"],
    "env": {
      "FIGMA_ACCESS_TOKEN": "your-token-here"
    }
  }
}
```

### Step 4: Verify Installation
1. Restart Claude Desktop
2. In a new conversation, type: `@figma status`
3. Should see: "Figma MCP connected"

### Using Figma MCP with Claude

#### Basic Commands
```
@figma list files
@figma get file [file-key]
@figma export component [component-id] as SwiftUI
```

#### Design to Code Workflow
1. **In Figma**: Design your menu bar interface
2. **Get File Key**: From Figma URL (figma.com/file/FILEKEY/...)
3. **In Claude**: 
   ```
   @figma analyze file abc123xyz
   Convert the MenuBar component to SwiftUI code
   ```

#### Example Conversion Request
```
@figma export MenuBarDropdown as SwiftUI
Add Touch ID authentication to the Arm/Disarm buttons
Make the status text update based on armed state
```

### Advanced MCP Features

#### Auto-sync Design Changes
```json
{
  "figma": {
    "command": "node",
    "args": ["/path/to/mcp-server"],
    "env": {
      "FIGMA_ACCESS_TOKEN": "your-token",
      "FIGMA_FILE_KEY": "your-file-key",
      "AUTO_SYNC": "true"
    }
  }
}
```

#### Custom Export Templates
Create `.mcp/templates/menu-bar.hbs`:
```handlebars
MenuBarExtra("{{title}}", systemImage: "{{icon}}") {
  {{#each menuItems}}
  Button("{{label}}") {
    {{action}}()
  }
  {{/each}}
}
```

### Troubleshooting

#### Common Issues
1. **"Figma MCP not found"**
   - Verify npm installation path
   - Check Claude Desktop server config

2. **"Invalid API token"**
   - Regenerate token in Figma
   - Update in Claude config
   - Restart Claude Desktop

3. **"Cannot export component"**
   - Ensure component is properly named
   - Check component is not in draft state
   - Verify API token has read access

#### Debug Mode
Add to configuration:
```json
"env": {
  "FIGMA_ACCESS_TOKEN": "your-token",
  "DEBUG": "figma:*"
}
```

### Best Practices
1. Name Figma components clearly (e.g., "MenuBarIcon_Armed")
2. Use Figma's component properties for variants
3. Group related designs in frames
4. Add descriptions to components for better AI context
5. Use consistent naming between Figma and code

### Security Notes
- Never commit Figma API tokens to git
- Store tokens in environment variables
- Rotate tokens periodically
- Use read-only tokens when possible