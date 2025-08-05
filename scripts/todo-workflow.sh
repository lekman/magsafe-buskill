#!/bin/bash

# MagSafe Guard TODO Workflow Manager
# Manages .todo.md queue and executes tasks with QA validation

set -e

echo "📋 MagSafe Guard TODO Workflow Manager"
echo "=================================="
echo ""

# Function to add item to .todo.md queue
add_to_queue() {
  local item="$1"
  local source="$2"
  
  # Check if item already exists in queue
  if grep -q "$item" .todo.md 2>/dev/null; then
    echo "ℹ️  Already in queue: $item"
    return
  fi
  
  # Add to queue section
  if grep -q "No prompts in queue." .todo.md 2>/dev/null; then
    # Replace "No prompts in queue" with first item
    sed -i.bak "s/No prompts in queue./### $source\n\n- $item/" .todo.md
    rm -f .todo.md.bak
  else
    # Add before the Critical Issues section
    sed -i.bak "/## \*\*Critical Issues/i\\
- $item" .todo.md
    rm -f .todo.md.bak
  fi
  echo "✅ Added to queue: $item"
}

# Function to collect findings from AI review
collect_ai_findings() {
  echo "🤖 Collecting AI findings..."
  
  if [ -f ".architecture.review.md" ]; then
    # Extract critical issues
    sed -n '/Critical Issues/,/Overall Architecture Score/p' .architecture.review.md | grep '^[0-9]\.' | while IFS= read -r line; do
      issue=$(echo "$line" | sed 's/^[0-9]*\. \*\*//; s/\*\* .*//')
      add_to_queue "Fix: $issue" "AI Architecture Review"
    done
  fi
  
  if [ -f ".qa.review.md" ]; then
    # Extract QA findings  
    grep '^- ' .qa.review.md | head -5 | while IFS= read -r line; do
      finding=$(echo "$line" | sed 's/^- //')
      add_to_queue "Address: $finding" "QA Review"
    done
  fi
}

# Function to collect QA issues
collect_qa_findings() {
  echo "🔍 Running QA checks for new findings..."
  
  # Run QA and capture output
  qa_output=$(task qa 2>&1 || echo "QA checks found issues")
  
  # Parse common issues
  if echo "$qa_output" | grep -q "failed"; then
    add_to_queue "Fix failing QA checks" "QA Scanner"
  fi
  
  if echo "$qa_output" | grep -q "warning"; then
    warning_count=$(echo "$qa_output" | grep -c "warning")
    add_to_queue "Resolve $warning_count warning(s)" "QA Scanner"
  fi
}

# Function to work on tasks
work_on_tasks() {
  echo "🔨 Starting task execution workflow..."
  
  # Check if there are queued items
  if grep -q "No prompts in queue." .todo.md; then
    echo "📋 No queued prompts. Working on critical issues..."
    
    # Work on first critical issue
    first_issue=$(sed -n '/## \*\*Critical Issues/,/## \*\*Specific Security/p' .todo.md | grep '^### [0-9]' | head -1)
    if [ -n "$first_issue" ]; then
      echo "🎯 Starting work on: $first_issue"
      echo ""
      echo "⚠️  Manual intervention required for security fixes."
      echo "   Review the recommendations in .todo.md and implement changes."
      echo "   Run 'task qa' after each fix, then 'task commit' to save progress."
      echo ""
      echo "💡 Suggested workflow:"
      echo "   1. Fix the security issue following the recommendations"
      echo "   2. Run: task qa"
      echo "   3. Run: task commit"
      echo "   4. Run: task todo (to continue with next item)"
    else
      echo "✅ All tasks completed!"
    fi
    return
  fi
  
  # Extract first queued item
  first_item=$(sed -n '/## \*\*User Prompts In Queue:\*\*/,/## \*\*Critical Issues/ {
    /^- /p
  }' .todo.md | head -1 | sed 's/^- //')
  
  if [ -z "$first_item" ]; then
    echo "✅ Queue is empty. Moving to critical issues..."
    work_on_tasks
    return
  fi
  
  echo "🎯 Working on: $first_item"
  echo ""
  
  # Run QA before making changes
  echo "🔍 Running QA check before changes..."
  if task qa >/dev/null 2>&1; then
    echo "✅ QA passed"
  else
    echo "⚠️  QA issues detected - will fix during task execution"
  fi
  
  echo ""
  echo "⚠️  Manual intervention required."
  echo "   Please implement the changes for: $first_item"
  echo "   After making changes:"
  echo "   1. Run: task qa"
  echo "   2. Run: task commit"
  echo "   3. Run: task todo:complete '$first_item'"
  echo ""
}

# Main workflow
if [ "$1" = "complete" ]; then
  # Remove completed item from queue
  completed_item="$2"
  if [ -n "$completed_item" ]; then
    # Remove the item from queue
    sed -i.bak "/^- .*$completed_item.*/d" .todo.md
    rm -f .todo.md.bak
    
    # Check if queue is now empty
    if ! sed -n '/## \*\*User Prompts In Queue:\*\*/,/## \*\*Critical Issues/ {
      /^- /p
    }' .todo.md | grep -q '^- '; then
      # Set back to "No prompts in queue"
      sed -i.bak 's/### .*/No prompts in queue./' .todo.md
      rm -f .todo.md.bak
    fi
    
    echo "✅ Completed: $completed_item"
    echo "🔄 Running todo workflow to continue..."
    exec "$0"
  else
    echo "❌ Please specify the completed item"
    echo "Usage: task todo:complete 'item description'"
  fi
else
  # Regular todo workflow
  collect_ai_findings
  collect_qa_findings
  work_on_tasks
fi