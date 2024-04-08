#!/usr/bin/env bash

BUMP=${BUMP:-patch} #minor major
PACKAGE_JSON=${PACKAGE_JSON:-package.json}
# MASTER_BRANCH=$(git branch --show-current)
MASTER_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
# BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
operation=$1
BRANCH_NAME=${2:-$BRANCH_NAME}
PACKAGE_MANAGER=$(echo "$@" | cut -d ' ' -f 3-)
# BUILD_NUMBER=0

USAGE="\
Options:
  -v, --version          Print the version of this tool.
  -h, --help             Print this help message.

Commands:
  bump        Bump by one of major, minor, patch (by default) version of main branch only. 
              Add git-tag and push if 'git' option.
              Read and update package.json version if 'npm' option.
              E.g. 'bump \$CURRENT_BRANCH git npm'

  latest      Return latest git-tag. Specify 'commit_sha' to get tag of the commit if exists

  docker_tag  Normalize string to docker-tag.
  "

function get_package_version() {
  PACKAGE_MANAGER=$1

  if [ "$PACKAGE_MANAGER" = "npm" ]; then
    jq -r '.version' ${2:-./package.json}
  fi
}

function set_package_version() {
  VERSION=$1
  PACKAGE_MANAGER=$2
  
  if [ "$PACKAGE_MANAGER" = "npm" ]; then
    TMP=$(mktemp)
    jq --arg version "$VERSION" '.version=$version' "${3:-./package.json}" > "$TMP" && mv "$TMP" "${3:-./package.json}"
  fi
  echo ${3:-package.json}
}

function bump_version() {
  # echo "bump_version"
  # echo "$@"
  GIT_MANAGER=$(echo "$@" | grep -o "git" || echo "")
  PACKAGE_MANAGER=$(echo "$@" | sed 's/[[:space:]]*git[[:space:]]*//g')
  # GIT_VERSION=$(git tag -l --sort=-creatordate | head -n 1)
  echo "TAGS $(git describe --tags --abbrev=0)"
  GIT_REPO_SSH_URL=$(git remote get-url origin)
  GIT_VERSION=$(latest $GIT_REPO_SSH_URL) # Get latest git-tag of the branch
  VERSION="${GIT_VERSION:-0.0.0}"
  APP_VERSION="$VERSION"
  if [ -n "$PACKAGE_MANAGER" ]; then
    APP_VERSION=$(get_package_version $PACKAGE_MANAGER)
  fi
  # echo "VERSION $VERSION, GIT_VERSION $GIT_VERSION, APP_VERSION $APP_VERSION, GIT_MANAGER $GIT_MANAGER, PACKAGE_MANAGER $PACKAGE_MANAGER"

  if [ "$VERSION" = "$APP_VERSION" ] # Auto increment
  then 
      BUMPED_VERSION=$(semver.sh bump $BUMP $VERSION)
      # echo "Increment version $VERSION -> $BUMPED_VERSION"
      VERSION="$BUMPED_VERSION"
      
      if [ -n "$PACKAGE_MANAGER" ]; then
        AFFECTED_FILES=$(set_package_version "$VERSION" "$PACKAGE_MANAGER")
        git add "$AFFECTED_FILES"
        git commit --allow-empty -q -m "Release version $VERSION"
      fi
  elif [ -n "$APP_VERSION" ] # Manual increment
  then
      # echo "Update version from package.json $VERSION -> $APP_VERSION"
      VERSION="$APP_VERSION"
  # else
  #     echo "Use version from GIT-tag $VERSION"
  fi

  if [ -n "$GIT_MANAGER" ]; then
    git tag -f "$VERSION"
    git push -q --follow-tags --no-verify origin $(get_master_branch_name) "$VERSION"
  fi

  echo $VERSION
}

function latest() {
  if [ -n "$1" ]; then
    git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' $1 | tail -n1 | awk '{print $2}' | sed 's@refs/tags/@@' || echo "0.0.0"
  else
    git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0"
    # git describe --tags --abbrev=0 $1 2>/dev/null || echo "0.0.0"
  fi
}

function get_commit_tag() {
  git tag --points-at $1
}

function get_remote_branch_by_commit() {
  git ls-remote --heads $1 | while read sha refs; do # Repo url
    if [[ $sha == $2 ]]; then # Commit id
        echo "$(echo $refs | sed 's@refs/heads/@@')"
    fi
  done
}

function get_master_branch_name() {
  if [ -n "$1" ]; then
    # git ls-remote --symref "$1" HEAD
    # git ls-remote --symref $1 HEAD | awk '/HEAD/ {split($2, a, "/"); print a[3]}'
    git ls-remote --symref $1 HEAD | awk '{print $2}' | head -n 1 | sed 's@refs/heads/@@'
    # git ls-remote --symref $1 HEAD | awk '{print $2}' | head -n 1 | sed 's@refs/heads/@@' # 2>/dev/null
    # git ls-remote --symref "$REPO_URL" | awk '/HEAD/ {print $2}' | head -n 1 | sed 's@refs/heads/@@'
  else
    git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
  fi
}

function docker_tag() {
  echo "$1" | tr -s '[:blank:]' '_' | tr -cd '[:alnum:]._-' | tr '[:upper:]' '[:lower:]'; echo
}


# if [ -z "$(git tag --contains $PROJECT_COMMIT_SHA)" ]; then
#   echo "Commit does not have a tag"
# fi
# echo "+++ $operation"

if [ "$operation" = "bump" ]; then
  if [ "$BRANCH_NAME" = "$MASTER_BRANCH" ]
  then
    bump_version "$PACKAGE_MANAGER"
  fi
elif [ "$operation" = "docker_tag" ]; then
  docker_tag "$BRANCH_NAME"

elif [ "$operation" = "latest" ]; then
  latest "$BRANCH_NAME"

elif [ "$operation" = "get_commit_tag" ]; then
  get_commit_tag "$BRANCH_NAME"

elif [ "$operation" = "get_master_branch_name" ]; then
  get_master_branch_name "$BRANCH_NAME"

elif [ "$operation" = "get_remote_branch_by_commit" ]; then
  get_remote_branch_by_commit "$BRANCH_NAME" "$PACKAGE_MANAGER"

elif [ "$operation" = "-v" ] || [ "$operation" = "--version" ]; then
  echo "0.0.1"

elif [ "$operation" = "-h" ] || [ "$operation" = "--help" ]; then
  echo "$USAGE"

else
  echo "Allowed operations are: bump, latest, docker_tag"
fi

# git log -1 --pretty=format:%H