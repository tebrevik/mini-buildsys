# mini-buildsys
A simple bash-based build system that you can use when jenkins, etc. are too complicated for your mini projects. Please note that the intent of this script is to build docker images and only that. All build processing is happening inside docker build.
It's made to be run from a cron-job to pull updates from remote repository, build and if target repository has been tagged then push to a docker repository with that tag as a version tag.

### Notes about git tags
I'm using git tags in my repositories to determine if this build is to be a release or not. If the target repository HEAD is tagged with say 0.1.0 then the docker image will be tagged with :0.1.0 and pushed to the docker repository.  If it's not tagged then it's just built and not pushed to a docker repository, in other words then it's just a build step to check the integrity of the commit.

## Usage
run.sh need the following to be useful:

### MINI_BUILDSYS_DOCKER_REPO_URL
Environment variable MINI_BUILDSYS_DOCKER_REPO_URL specifying URL to your docker repository. This is used for pushing tagged images to your docker repository.

example: MINI_BUILDSYS_DOCKER_REPO_URL=localhost:34371 for using a docker repository listening on port 34371 

### MINI_BUILDSYS_GIT_BASE_URL
Environment variable MINI_BUILDSYS_GIT_BASE_URL specifying base path to your git account.

example: MINI_BUILDSYS_GIT_BASE_URL=git@github.com:your-account-name

### target-config.conf
A simple configuration file where each target repository is specified one per line.
```
repository-one
repository-two
```
This will then clone ${MINI_BUILDSYS_GIT_BASE_URL}/repository-one and ${MINI_BUILDSYS_GIT_BASE_URL}/repository-two.
The resulting docker images, if tagged, will be pushed to ${MINI_BUILDSYS_DOCKER_REPO_URL}/repository-one:tag and ${MINI_BUILDSYS_DOCKER_REPO_URL}/repository-two:tag

### crontab example:
```
*/30 * * * * MINI_BUILDSYS_DOCKER_REPO_URL=localhost:34371 MINI_BUILDSYS_GIT_BASE_URL=git@github.com:your-account-name ~/build/run.sh >/dev/null
```
This will set the necessary environment variables, run every 30 minutes and only send email on errors
