#!/bin/bash
# validate-tasks.sh - Validate Zed tasks.json format

set -e

TASKS_FILE=".zed/tasks.json"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Zed tasks.json format..."

# Check if tasks.json exists
if [[ ! -f "$TASKS_FILE" ]]; then
    echo -e "${RED}❌ Error: $TASKS_FILE not found${NC}"
    exit 1
fi

# Check if it's valid JSON
if ! jq . "$TASKS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: $TASKS_FILE contains invalid JSON${NC}"
    exit 1
fi

# Check if it's an array (Zed format) not an object (VS Code format)
if ! jq -e 'type == "array"' "$TASKS_FILE" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: $TASKS_FILE should be an array, not an object${NC}"
    echo -e "${YELLOW}💡 Hint: Zed uses array format, VS Code uses object format${NC}"
    exit 1
fi

# Validate each task has required fields
task_count=$(jq length "$TASKS_FILE")
echo "📋 Found $task_count tasks"

valid_tasks=0
for i in $(seq 0 $((task_count - 1))); do
    task=$(jq ".[$i]" "$TASKS_FILE")
    label=$(echo "$task" | jq -r '.label // "unnamed"')

    echo -n "  • $label: "

    # Check required fields
    if ! echo "$task" | jq -e 'has("command")' >/dev/null 2>&1; then
        echo -e "${RED}❌ Missing 'command' field${NC}"
        continue
    fi

    if ! echo "$task" | jq -e 'has("label")' >/dev/null 2>&1; then
        echo -e "${RED}❌ Missing 'label' field${NC}"
        continue
    fi

    # Check for VS Code specific fields that shouldn't be in Zed format
    vs_code_fields=("group" "presentation" "problemMatcher" "runOptions")
    has_vs_code_fields=false

    for field in "${vs_code_fields[@]}"; do
        if echo "$task" | jq -e "has(\"$field\")" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Contains VS Code field '$field'${NC}"
            has_vs_code_fields=true
        fi
    done

    if [[ "$has_vs_code_fields" == false ]]; then
        echo -e "${GREEN}✅ Valid${NC}"
        ((valid_tasks++))
    fi
done

echo ""
echo "📊 Validation Summary:"
echo "  Total tasks: $task_count"
echo "  Valid tasks: $valid_tasks"

if [[ $valid_tasks -eq $task_count ]]; then
    echo -e "${GREEN}🎉 All tasks are valid for Zed format!${NC}"
    exit 0
else
    invalid_tasks=$((task_count - valid_tasks))
    echo -e "${RED}❌ $invalid_tasks tasks need attention${NC}"
    echo ""
    echo "📖 Zed Task Format Reference:"
    echo "  • Use array format: [{ ... }, { ... }]"
    echo "  • Required fields: 'label', 'command'"
    echo "  • Common fields: 'args', 'reveal', 'hide', 'use_new_terminal'"
    echo "  • Avoid VS Code fields: 'group', 'presentation', 'problemMatcher'"
    echo ""
    echo "🔗 Documentation: https://zed.dev/docs/tasks"
    exit 1
fi
