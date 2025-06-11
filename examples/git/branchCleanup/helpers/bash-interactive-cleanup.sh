#!/usr/bin/env bash

# shellcheck disable=SC2155
# shellcheck disable=SC1091
# shellcheck disable=SC2016
# shellcheck disable=SC2034
set -euo pipefail

source "$DRUN_CONFIG/helpers/git.sh"

# Global variables for cleanup
ORIGINAL_BRANCH=""
TEMP_FILES=()
STASH_CREATED=false

# Colors and symbols
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
ORANGE='\033[0;38m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

LOCAL_ICON="💻 "
REMOTE_ICON="🌐 "
ABSENT_ICON="⬛ "
# Branch status symbols
MERGED_ICON="	✅ "
SQUASH_MERGED_ICON="	📦 "
AHEAD_ICON="	⬆️ "
BEHIND_ICON="	⬇️ "
DIVERGED_ICON="	🔀 "
UNTRACKED_ICON="	🆕 "
CURRENT_ICON="	👉 "

MERGED_COLOR=$GREEN
SQUASH_MERGED_COLOR=$GREEN
AHEAD_COLOR=$BLUE
BEHIND_COLOR=$MAGENTA
DIVERGED_COLOR=$YELLOW
UNTRACKED_COLOR=$GRAY
CURRENT_COLOR=$CYAN

# Cleanup function for graceful exit
cleanup_on_exit() {
	local exit_code=$?

	# Remove temp files
	for temp_file in "${TEMP_FILES[@]}"; do
		[[ -f "$temp_file" ]] && rm -f "$temp_file"
	done

	# Restore original branch if we're not on it
	if [[ -n "$ORIGINAL_BRANCH" ]]; then
		local current_branch
		current_branch=$(git_current_branch 2>/dev/null || echo "")

		if [[ "$current_branch" != "$ORIGINAL_BRANCH" ]] && git show-ref --verify --quiet "refs/heads/$ORIGINAL_BRANCH"; then
			echo -e "\n${YELLOW}🔄 Restoring original branch: $ORIGINAL_BRANCH${NC}"
			git checkout "$ORIGINAL_BRANCH" >/dev/null 2>&1 || true
		fi
	fi

	# Restore stashed changes if we created a stash
	if [[ "$STASH_CREATED" == "true" ]]; then
		echo -e "${CYAN}📦 Restoring stashed changes...${NC}"
		if git stash pop >/dev/null 2>&1; then
			echo -e "${GREEN}✓ Stashed changes restored${NC}"
		else
			echo -e "${YELLOW}⚠️  Could not restore stashed changes automatically${NC}"
			echo -e "${GRAY}   You can manually restore with: git stash pop${NC}"
		fi
	fi

	if [[ $exit_code -ne 0 ]]; then
		echo -e "\n${YELLOW}⏹️  Branch cleanup interrupted${NC}"
	fi

	exit $exit_code
}

# Set up signal handlers
trap cleanup_on_exit EXIT INT TERM

# Ensure we're in a git repository
git_repo_root >/dev/null || {
	echo "Not in a git repository. Exiting."
	exit 1
}

# Helper functions
create_temp_file() {
	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")
	echo "$temp_file"
}

check_and_stash_changes() {
	# Check if there are any uncommitted changes
	if ! git diff-index --quiet HEAD -- 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
		echo -e "${YELLOW}📦 Uncommitted changes detected. Stashing them for safekeeping...${NC}"

		# Add all tracked and untracked files to staging for stashing
		git add -A >/dev/null 2>&1

		# Create a stash with a descriptive message
		local stash_message="Auto-stash by branch cleanup script on $(date '+%Y-%m-%d %H:%M:%S')"
		if git stash push -m "$stash_message" >/dev/null 2>&1; then
			STASH_CREATED=true
			echo -e "${GREEN}✓ Changes stashed successfully${NC}"
			echo -e "${GRAY}   Stash message: $stash_message${NC}"
		else
			echo -e "${RED}⚠️  Failed to stash changes. Please commit or stash manually.${NC}"
			echo -e "${GRAY}   Script will continue but your changes may be at risk.${NC}"
			read -p "Continue anyway? (y/N): " -r confirm
			if [[ ! $confirm =~ ^[Yy]$ ]]; then
				echo -e "${YELLOW}⏭️  Script cancelled for safety${NC}"
				exit 1
			fi
		fi
		echo ""
	fi
}

get_relative_date() {
	local commit_date="$1"
	local now
	local diff_seconds
	local diff_days

	now=$(date +%s)
	diff_seconds=$((now - $(date -d "$commit_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S %z" "$commit_date" +%s 2>/dev/null || echo "$now")))
	diff_days=$((diff_seconds / 86400))

	if [[ $diff_days -eq 0 ]]; then
		echo "today"
	elif [[ $diff_days -eq 1 ]]; then
		echo "yesterday"
	elif [[ $diff_days -lt 7 ]]; then
		echo "${diff_days} days ago"
	elif [[ $diff_days -lt 30 ]]; then
		echo "$((diff_days / 7)) weeks ago"
	else
		echo "$((diff_days / 30)) months ago"
	fi
}

extract_pr_number() {
	local branch_name="$1"

	# Common PR number patterns
	if [[ $branch_name =~ pr[/-]?([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	elif [[ $branch_name =~ pull[/-]?([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	elif [[ $branch_name =~ ([0-9]+)[-_]pr ]]; then
		echo "${BASH_REMATCH[1]}"
	elif [[ $branch_name =~ feature[/-]([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
	elif [[ $branch_name =~ ([0-9]+)$ ]]; then
		echo "${BASH_REMATCH[1]}"
	else
		echo ""
	fi
}

is_branch_merged() {
	local branch_name="$1"
	local default_branch="$2"

	# Count unique commits that are NOT in origin/master
	local unique_commits
	unique_commits=$(git rev-list --count "$branch_name" --not "origin/$default_branch" 2>/dev/null || echo "1")

	# A branch is considered merged if it has NO unique commits
	if [[ "$unique_commits" -eq 0 ]]; then
		return 0 # Branch is merged - all commits are already in origin/master
	fi

	return 1 # Branch is not merged - has unique commits
}

is_branch_squash_merged() {
	local branch_name="$1"
	local default_branch="$2"

	# Check if this could be a squash-merged branch
	# Criteria:
	# 1. Has unique commits (not in origin/master)
	# 2. Remote branch is gone (deleted after merge)
	# 3. Recent commits suggest it was merged

	# Count unique commits
	local unique_commits
	unique_commits=$(git rev-list --count "$branch_name" --not "origin/$default_branch" 2>/dev/null || echo "0")

	# Must have unique commits to be squash-merged
	if [[ "$unique_commits" -eq 0 ]]; then
		return 1 # No unique commits = regular merge
	fi

	# Check if remote branch is gone (strong indicator of squash-merge)
	local has_remote
	has_remote=$(git show-ref --verify --quiet "refs/remotes/origin/$branch_name" && echo "true" || echo "false")

	if [[ "$has_remote" == "false" ]]; then
		# Remote branch is gone - likely squash-merged

		# Additional check: Look for similar commit messages in recent master history
		# Get the branch's unique commit messages
		local branch_messages
		branch_messages=$(git log --format="%s" "$branch_name" --not "origin/$default_branch" 2>/dev/null | head -3)

		if [[ -n "$branch_messages" ]]; then
			# Check if any similar patterns exist in recent master commits
			local recent_master_messages
			recent_master_messages=$(git log --format="%s" "origin/$default_branch" --since="30 days ago" 2>/dev/null)

			# Look for branch name patterns or similar words in master
			local branch_basename
			branch_basename=$(echo "$branch_name" | sed 's/.*\///g' | sed 's/[-_]/ /g')

			if echo "$recent_master_messages" | grep -qi "$branch_basename" 2>/dev/null; then
				return 0 # Likely squash-merged
			fi

			# Check for PR pattern in master
			if echo "$recent_master_messages" | grep -E "#[0-9]+" >/dev/null 2>&1; then
				return 0 # Likely squash-merged (has PR references)
			fi
		fi

		return 0 # Remote gone = likely squash-merged
	fi

	return 1 # Not squash-merged
}

get_branch_info() {
	local branch_line="$1"
	local default_branch="$2"
	local current_branch="$3"

	# Parse git branch -vv output
	local is_current=false
	local clean_line="$branch_line"

	if [[ $branch_line =~ ^\* ]]; then
		is_current=true
		clean_line="${branch_line#* }"
	fi

	# Extract branch name (first word)
	local branch_name
	branch_name=$(echo "$clean_line" | awk '{print $1}')

	# Also check if this branch matches the original current branch
	# (in case we've checked out a different branch during script execution)
	if [[ "$branch_name" == "$current_branch" ]]; then
		is_current=true
	fi

	# Skip if it's a protected branch
	if [[ "$branch_name" == "$default_branch" ]] || [[ "$branch_name" =~ ^(main|master|develop)$ ]]; then
		return 0
	fi

	# Extract ahead/behind info
	local ahead=0
	local behind=0
	if [[ $clean_line =~ ahead\ ([0-9]+) ]]; then
		ahead="${BASH_REMATCH[1]}"
	fi
	if [[ $clean_line =~ behind\ ([0-9]+) ]]; then
		behind="${BASH_REMATCH[1]}"
	fi

	# Extract remote tracking branch
	local tracking=""
	if [[ $clean_line =~ \[([^\]]+)\] ]]; then
		tracking="${BASH_REMATCH[1]}"
		tracking="${tracking%%:*}" # Remove everything after ':'
	fi

	# Determine remote status with icons
	local remote_status
	local has_remote=false

	if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
		has_remote=true
	fi

	if [[ "$has_remote" == "true" ]]; then
		if [[ $clean_line =~ gone ]]; then
			remote_status="${LOCAL_ICON}${REMOTE_ICON}(gone)"
		else
			remote_status="${LOCAL_ICON}${REMOTE_ICON}"
		fi
	else
		remote_status="${LOCAL_ICON}${ABSENT_ICON}"
	fi

	# Get commit info - look for the author of unique commits, not just the last commit
	local last_commit_date
	local last_author
	last_commit_date=$(git log -1 --format="%ai" "$branch_name" 2>/dev/null || echo "")

	# Try to get the author of unique commits (commits not in origin/master)
	local unique_author
	unique_author=$(git log --format="%an" "$branch_name" --not "origin/$default_branch" 2>/dev/null | head -1)

	if [[ -n "$unique_author" ]]; then
		last_author="$unique_author"
	else
		# Fallback to last commit author
		last_author=$(git log -1 --format="%an" "$branch_name" 2>/dev/null || echo "Unknown")
	fi

	# Check if merged (proper check)
	local is_merged=false
	local is_squash_merged=false
	if is_branch_merged "$branch_name" "$default_branch"; then
		is_merged=true
	elif is_branch_squash_merged "$branch_name" "$default_branch"; then
		is_squash_merged=true
	fi

	# Extract PR number
	local pr_number
	pr_number=$(extract_pr_number "$branch_name")

	# Determine branch type and color
	local icon color status_text
	if [[ "$is_current" == "true" ]]; then
		icon="$CURRENT_ICON"
		color="$CURRENT_COLOR"
		status_text="Current branch"
	elif [[ "$is_merged" == "true" ]]; then
		icon="$MERGED_ICON"
		color="$MERGED_COLOR"
		status_text="Merged"
	elif [[ "$is_squash_merged" == "true" ]]; then
		icon="$SQUASH_MERGED_ICON"
		color="$SQUASH_MERGED_COLOR"
		status_text="Squash-merged"
	elif [[ $ahead -gt 0 && $behind -eq 0 ]]; then
		icon="$AHEAD_ICON"
		color="$AHEAD_COLOR"
		status_text="Ahead of HEAD"
	elif [[ $behind -gt 0 && $ahead -eq 0 ]]; then
		icon="$BEHIND_ICON"
		color="$BEHIND_COLOR"
		status_text="Behind HEAD"
	elif [[ $ahead -gt 0 && $behind -gt 0 ]]; then
		icon="$DIVERGED_ICON"
		color="$DIVERGED_COLOR"
		status_text="Diverged"
	elif [[ -z "$tracking" ]]; then
		icon="$UNTRACKED_ICON"
		color="$UNTRACKED_COLOR"
		status_text="No remote tracking"
	else
		icon="$AHEAD_ICON"
		color="$AHEAD_COLOR"
		status_text="New branch"
	fi

	# Calculate relative date
	local relative_date
	if [[ -n "$last_commit_date" ]]; then
		relative_date=$(get_relative_date "$last_commit_date")
	else
		relative_date="unknown"
	fi

	# Build status line
	local status_line="$relative_date • $last_author"
	if [[ -n "$pr_number" ]]; then
		status_line="$status_line • PR #$pr_number"
	fi
	if [[ $ahead -gt 0 || $behind -gt 0 ]]; then
		local commits_info=""
		[[ $ahead -gt 0 ]] && commits_info="↑$ahead"
		[[ $behind -gt 0 ]] && commits_info="$commits_info ↓$behind"
		status_line="$status_line • $commits_info"
	fi

	# Output format: branch_name|icon|color|status_text|status_line|is_current|is_merged|last_commit_date|remote_status|is_squash_merged
	echo "$branch_name|$icon|$color|$status_text|$status_line|$is_current|$is_merged|$last_commit_date|$remote_status|$is_squash_merged"
}

display_branch_list() {
	local branches_info_file="$1"
	local selected_file="$2"

	echo -e "${BLUE}🧹 Interactive Git Branch Cleanup${NC}\n"
	echo -e "${GRAY}Original branch: $ORIGINAL_BRANCH${NC}"
	echo -e "${GRAY}Default branch: $(git_default_branch)${NC}\n"

	local count=0
	local branch_count
	branch_count=$(wc -l <"$branches_info_file")

	if [[ $branch_count -eq 0 ]]; then
		echo -e "${GREEN}✨ No branches available for cleanup!${NC}"
		echo -e "${GRAY}(Only the default branch and current branch are excluded)${NC}"
		return 1
	fi

	echo -e "${GRAY}Found $branch_count branches. Numbers 1-9 can be used for quick selection${NC}\n"

	while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
		local selected_indicator=" "

		# Check if this branch is selected
		if grep -q "^$branch_name$" "$selected_file" 2>/dev/null; then
			selected_indicator="🔵"
		else
			selected_indicator="⚫"
		fi

		# Format the line
		if [[ "$is_current" == "true" ]]; then
			echo -e "- ${icon}${color}${branch_name}${NC} ${GRAY}${status_text}${NC}"
			echo -e "	  ${GRAY}${status_line} • (${remote_status})${NC}"
		else
			((count++))
			local number_prefix=""
			if [[ $count -le 9 ]]; then
				number_prefix="$count) "
			else
				number_prefix="   "
			fi
			echo -e "$number_prefix$selected_indicator ${icon}${color}${branch_name}${NC}"
			echo -e "	    ${GRAY}${status_line} • (${remote_status})${NC}"
		fi

	done <"$branches_info_file"

	return 0
}

interactive_branch_selection() {
	local branches_info_file="$1"
	local selected_file="$2"

	# Pre-select merged branches (including squash-merged)
	while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
		if [[ ("$is_merged" == "true" || "$is_squash_merged" == "true") && "$is_current" != "true" ]]; then
			echo "$branch_name" >>"$selected_file"
		fi
	done <"$branches_info_file"

	while true; do
		clear
		echo -e "${BLUE}🧹 Interactive Git Branch Selection${NC}\n"
		echo -e "${GRAY}Original branch: $ORIGINAL_BRANCH${NC}"
		echo -e "${GRAY}Default branch: $(git_default_branch)${NC}\n"

		display_branch_list "$branches_info_file" "$selected_file"

		echo -e "\n${CYAN}Currently selected branches:${NC}"
		if [[ -s "$selected_file" ]]; then
			local count=0
			# shellcheck disable=SC2034
			while read -r branch; do
				((count++))
			done <"$selected_file"
			echo -e "${GRAY}  Total: $count branches${NC}"
		else
			echo -e "  ${GRAY}(none selected)${NC}"
		fi

		echo
		# ADD ICON LEGEND HERE
		echo -e "${CYAN}Icon Legend:${NC}"
		echo -e "${MERGED_ICON} ${MERGED_COLOR}Merged branches${NC}"
		echo -e "${SQUASH_MERGED_ICON} ${SQUASH_MERGED_COLOR}Squash merged branches${NC}"
		echo -e "${AHEAD_ICON} ${AHEAD_COLOR}Ahead of HEAD${NC}"
		echo -e "${BEHIND_ICON} ${BEHIND_COLOR}Behind HEAD${NC}"
		echo -e "${DIVERGED_ICON} ${DIVERGED_COLOR}Diverged${NC}"
		echo -e "${UNTRACKED_ICON} ${UNTRACKED_COLOR}No remote tracking${NC}"
		echo -e "${CURRENT_ICON} ${CURRENT_COLOR}Current branch${NC}"
		echo
		echo -e "\n${YELLOW}Options:${NC}"
		echo "  [1-9] Toggle specific branch by number"
		echo "  [a] Select all non-current branches"
		echo "  [m] Select only merged branches (default)"
		echo "  [n] Select none"
		echo "  [s] Show individual branch selection"
		echo "  [c] Continue with current selection"
		echo "  [q] Quit"

		read -p "Choice [c]: " -r choice
		choice=${choice:-c}

		case $choice in
		a | A)
			true >"$selected_file" # Clear file
			while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
				if [[ "$is_current" != "true" ]]; then
					echo "$branch_name" >>"$selected_file"
				fi
			done <"$branches_info_file"
			echo -e "${GREEN}✓ Selected all non-current branches${NC}"
			sleep 1
			;;
		m | M)
			true >"$selected_file" # Clear file
			while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
				if [[ ("$is_merged" == "true" || "$is_squash_merged" == "true") && "$is_current" != "true" ]]; then
					echo "$branch_name" >>"$selected_file"
				fi
			done <"$branches_info_file"
			echo -e "${GREEN}✓ Selected only merged branches${NC}"
			sleep 1
			;;
		n | N)
			true >"$selected_file" # Clear file
			echo -e "${GREEN}✓ Cleared selection${NC}"
			sleep 1
			;;
		s | S)
			individual_branch_selection "$branches_info_file" "$selected_file"
			;;
		c | C | "")
			break
			;;
		q | Q)
			echo -e "${YELLOW}⏭️  Cleanup cancelled${NC}"
			exit 0
			;;
		[1-9])
			toggle_branch_by_number "$choice" "$branches_info_file" "$selected_file"
			;;
		*)
			echo -e "${RED}Invalid choice. Please try again.${NC}"
			sleep 1
			;;
		esac
	done
}

toggle_branch_by_number() {
	local number="$1"
	local branches_info_file="$2"
	local selected_file="$3"

	local count=0
	local target_branch=""

	while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
		if [[ "$is_current" != "true" ]]; then
			((count++))
			if [[ $count -eq $number ]]; then
				target_branch="$branch_name"
				break
			fi
		fi
	done <"$branches_info_file"

	if [[ -n "$target_branch" ]]; then
		if grep -q "^$target_branch$" "$selected_file" 2>/dev/null; then
			# Remove from selection
			grep -v "^$target_branch$" "$selected_file" >"${selected_file}.tmp" && mv "${selected_file}.tmp" "$selected_file"
			echo -e "${YELLOW}✗ Deselected: $target_branch${NC}"
		else
			# Add to selection
			echo "$target_branch" >>"$selected_file"
			echo -e "${GREEN}✓ Selected: $target_branch${NC}"
		fi
		sleep 0.5
	else
		echo -e "${RED}Invalid branch number: $number${NC}"
		sleep 1
	fi
}

individual_branch_selection() {
	local branches_info_file="$1"
	local selected_file="$2"

	while true; do
		clear
		echo -e "${BLUE}🧹 Individual Branch Selection${NC}\n"
		echo -e "${GRAY}Type branch names to toggle selection (partial matching supported)${NC}"
		echo -e "${GRAY}Type 'done' to return to main menu${NC}"
		echo -e "${GRAY}Original branch: $ORIGINAL_BRANCH${NC}\n"

		local count=0
		while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status; do
			if [[ "$is_current" != "true" ]]; then
				((count++))
				local selected_indicator="◯"
				if grep -q "^$branch_name$" "$selected_file" 2>/dev/null; then
					selected_indicator="◉"
				fi
				echo -e "$count) $selected_indicator ${icon}${color}${branch_name}${NC} ${GRAY}($remote_status)${NC}"
			fi
		done <"$branches_info_file"

		echo
		read -p "Enter branch name or number (or 'done'): " -r input

		if [[ "$input" == "done" ]] || [[ "$input" == "d" ]]; then
			break
		elif [[ "$input" =~ ^[0-9]+$ ]]; then
			toggle_branch_by_number "$input" "$branches_info_file" "$selected_file"
			sleep 0.5
		else
			# Find matching branch names
			local matches=()
			while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
				if [[ "$is_current" != "true" && "$branch_name" == *"$input"* ]]; then
					matches+=("$branch_name")
				fi
			done <"$branches_info_file"

			if [[ ${#matches[@]} -eq 1 ]]; then
				local target_branch="${matches[0]}"
				if grep -q "^$target_branch$" "$selected_file" 2>/dev/null; then
					grep -v "^$target_branch$" "$selected_file" >"${selected_file}.tmp" && mv "${selected_file}.tmp" "$selected_file"
					echo -e "${YELLOW}✗ Deselected: $target_branch${NC}"
				else
					echo "$target_branch" >>"$selected_file"
					echo -e "${GREEN}✓ Selected: $target_branch${NC}"
				fi
				sleep 0.5
			elif [[ ${#matches[@]} -gt 1 ]]; then
				echo -e "${YELLOW}Multiple matches found:${NC}"
				for match in "${matches[@]}"; do
					echo "  - $match"
				done
				echo -e "${GRAY}Please be more specific${NC}"
				sleep 2
			else
				echo -e "${RED}No matching branches found${NC}"
				sleep 1
			fi
		fi
	done
}

show_deletion_summary() {
	local branches_info_file="$1"
	local selected_file="$2"

	if [[ ! -s "$selected_file" ]]; then
		echo -e "${YELLOW}⏭️  No branches selected for deletion.${NC}"
		return 1
	fi

	echo -e "\n${BLUE}📋 Deletion Summary:${NC}"
	echo "────────────────────────────────────────────────────────────────────────────────"

	local count=0
	while read -r selected_branch; do
		while IFS='|' read -r branch_name icon color status_text status_line is_current is_merged last_commit_date remote_status is_squash_merged; do
			if [[ "$branch_name" == "$selected_branch" ]]; then
				echo -e "${icon}${color}${branch_name}${NC}"
				echo -e "   ${GRAY}Last commit:${NC} $status_line"
				echo -e "   ${GRAY}Remote status:${NC} $remote_status"
				if [[ "$is_merged" == "true" ]]; then
					echo -e "   ${GREEN}✅ Merged into $(git_default_branch)${NC}"
				elif [[ "$is_squash_merged" == "true" ]]; then
					echo -e "   ${GREEN}📦 Squash-merged into $(git_default_branch)${NC}"
				fi
				echo
				((count++))
				break
			fi
		done <"$branches_info_file"
	done <"$selected_file"

	echo -e "${YELLOW}Total: $count branch(es) selected for deletion${NC}\n"

	read -p "Delete these local branches? (y/N): " -r confirm
	if [[ ! $confirm =~ ^[Yy]$ ]]; then
		echo -e "${YELLOW}⏭️  Branch deletion cancelled.${NC}"
		return 1
	fi

	# Ask about remote deletion
	echo
	read -p "Also delete remote branches on origin? (y/N): " -r delete_remote_confirm
	if [[ $delete_remote_confirm =~ ^[Yy]$ ]]; then
		export DELETE_REMOTE_BRANCHES=true
	else
		export DELETE_REMOTE_BRANCHES=false
	fi

	return 0
}

delete_branches() {
	local selected_file="$1"

	echo -e "\n${BLUE}🗑️  Deleting branches...${NC}\n"

	local success_count=0
	local fail_count=0
	local remote_success_count=0
	local remote_fail_count=0

	while read -r branch_name; do
		# Skip empty lines
		[[ -z "$branch_name" ]] && continue

		# Delete local branch
		if git branch -D "$branch_name" >/dev/null 2>&1; then
			echo -e "${GREEN}✓ Deleted local branch: $branch_name${NC}"
			success_count=$((success_count + 1))

			# Delete remote branch if requested and it exists
			if [[ "${DELETE_REMOTE_BRANCHES:-false}" == "true" ]]; then
				if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
					if git push origin --delete "$branch_name" >/dev/null 2>&1; then
						echo -e "${GREEN}  ✓ Deleted remote branch: origin/$branch_name${NC}"
						remote_success_count=$((remote_success_count + 1))
					else
						echo -e "${RED}  ✗ Failed to delete remote branch: origin/$branch_name${NC}"
						remote_fail_count=$((remote_fail_count + 1))
					fi
				else
					echo -e "${GRAY}  ℹ Remote branch origin/$branch_name does not exist${NC}"
				fi
			fi
		else
			echo -e "${RED}✗ Failed to delete local branch: $branch_name${NC}"
			fail_count=$((fail_count + 1))
		fi
	done <"$selected_file"

	echo -e "\n${GREEN}✅ Branch cleanup completed!${NC}"
	echo -e "${GRAY}Local branches - Successfully deleted: $success_count${NC}"
	if [[ $fail_count -gt 0 ]]; then
		echo -e "${GRAY}Local branches - Failed to delete: $fail_count${NC}"
	fi

	if [[ "${DELETE_REMOTE_BRANCHES:-false}" == "true" ]]; then
		echo -e "${GRAY}Remote branches - Successfully deleted: $remote_success_count${NC}"
		if [[ $remote_fail_count -gt 0 ]]; then
			echo -e "${GRAY}Remote branches - Failed to delete: $remote_fail_count${NC}"
		fi
	fi
}

main() {
	# Accept original branch as parameter, fallback to current branch detection
	if [[ $# -gt 0 && -n "$1" ]]; then
		ORIGINAL_BRANCH="$1"
	else
		ORIGINAL_BRANCH=$(git_current_branch)
	fi

	local default_branch
	default_branch=$(git_default_branch)

	echo -e "${BLUE}🧹 Starting branch cleanup${NC}"
	echo -e "   Current branch: $ORIGINAL_BRANCH"
	echo -e "   Default branch: $default_branch"
	echo ""

	# Check for uncommitted changes and stash them if needed
	check_and_stash_changes

	# Create temp files
	local branches_info_file
	local selected_file
	branches_info_file=$(create_temp_file)
	selected_file=$(create_temp_file)

	# Collect branch information
	echo -e "${GRAY}🔍 Analyzing branches...${NC}"

	while read -r branch_line; do
		if [[ -n "$branch_line" ]]; then
			local branch_info
			branch_info=$(get_branch_info "$branch_line" "$default_branch" "$ORIGINAL_BRANCH")
			if [[ -n "$branch_info" ]]; then
				echo "$branch_info" >>"$branches_info_file"
			fi
		fi
	done < <(git branch -vv)

	# Sort by merge status and date
	sort -t'|' -k7,7r -k8,8r "$branches_info_file" -o "$branches_info_file"

	# Interactive selection
	if ! interactive_branch_selection "$branches_info_file" "$selected_file"; then
		return 1
	fi

	# Show summary and confirm
	if ! show_deletion_summary "$branches_info_file" "$selected_file"; then
		return 1
	fi

	# Delete selected branches
	delete_branches "$selected_file"

	# Prune remote tracking branches
	echo -e "\n${GRAY}🌿 Pruning remote tracking branches${NC}"
	git remote prune origin

	echo -e "${GREEN}✅ Branch cleanup completed${NC}"
}

main "$@"
