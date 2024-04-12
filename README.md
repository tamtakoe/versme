# versme
Docker image source of version bumping for CI-CD

Manage GIT and NPM (package.json) tags

Based on Alpine image with `bash`, `git`, `openssh-client`, `jq` and `curl`. Uses the semver shell utility https://github.com/fsaintjacques/semver-tool/tree/master

### Docker image
```sh
tamtakoe/versme:0.0.1
```

### Usage
```sh
versme bump major|minor|patch|prerel|release [-b|--branch <branch>] [-t|--type <application-type>] [-p|--push] [-s|--skip] [-st|--skip-tag]
versme release major|minor|patch|prerel|release [-b|--branch <branch>] [-t|--type <application-type>] [-n|--number <build-number>] [-p|--push] [-s|--skip] [-st|--skip-tag] [-ss|--skip-snapshot]
versme get_app_version <application-type>
versme set_app_version <application-type> <version>
versme get_commit_tag_by_branch <branch>
versme get_commit_tag_by_commit <commit>
versme get_default_branch [<repository-url>]
versme get_remote_branch_by_commit <repository-url> <commit>
versme latest [<repository-url>]
versme docker_tag <string>
versme --help
versme --version

Arguments:
  <branch>           Branch name
  <branch>           Commit SHA
  <application-type> Type of application config. Only supported npm (package.json)
  <build-number>     Version suffix
  <version>          Semver version
  <repository-url>   Repository URL

Options:
  -v, --version      Print the version of this tool.
  -h, --help         Print this help message.

Commands:
  bump        Bump by one of major, minor, patch version of branch. Default branch (main or master) if --branch not specify. 
              Add git-tag and push if --push option.
              Read and update application version if --type option. package.json for npm type
              Mark any push as skip-ci if --skip option or push tag only if --skip-tag option
              E.g. 'bump master -t npm --push'
              If APP_VERSION = GIT_TAG_VERSION - Increment git-tag and app-version (push version-file and git-tag)
              If APP_VERSION > GIT_TAG_VERSION - Set git-tag in app-version (git-tag)
              If APP_VERSION < GIT_TAG_VERSION - Set app-version in git tag (push version-file)
              Return new version

  release     Update version tag
              E.g. 'release patch -b feature -n 123 -t npm -p -st -ss'
              If BRANCH = DEFAULT_BRANCH - Bump version. See bump arguments
              If BRANCH != DEFAULT_BRANCH and not --skip-snapshot - Make shapshot tag <current-version>-<branch-name>.<build-number>
              Return docker compatibility version tag

  get_app_version             Get version tag from application config (e.g. for package.json if --type npm)

  set_app_version             Set version tag to application config (e.g. for package.json if --type npm)

  get_commit_tag_by_branch    Get nearest tag of local repository by branch name

  get_commit_tag_by_commit    Get tag of local repository by commit SHA

  get_default_branch          Get default branch name of local or remote repository

  get_remote_branch_by_commit Get branch name of remote repository by commit   

  latest                      Return latest git-tag. Specify 'commit_sha' to get tag of the commit if exists

  docker_tag                  Normalize string to docker-tag.
```

### Publish
```
docker build -t tamtakoe/versme:latest .
docker login
docker push tamtakoe/versme:latest
```