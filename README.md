# mini-buildsys
A simple bash-based build system that you can use when jenkins, etc. are too complicated for your mini projects.
Built to be run from a cron-job to pull updates from remote repository, build and if target repository has been tagged then push to a docker repository with that tag as a version tag.

### Notes about git tags
I'm using git tags in my repositories to determine if this build is to be a release or not. If the target repository HEAD is tagged with say 0.1.0 then the docker image will be tagged with :0.1.0.  If it's not tagged then it's just built and not pushed to a docker repository, in other words then it's just a build step to check the integrity of the commit.

## Usage
run.sh need the following to be useful:

### MINI_BUILDSYS_DOCKER_REPO_URL
Environment variable MINI_BUILDSYS_DOCKER_REPO_URL specifying URL to your docker repository. This is used for pushing tagged images to your docker repository.

example: MINI_BUILDSYS_DOCKER_REPO_URL=localhost:34371 for using a docker repository listening on port 34371 

### MINI_BUILDSYS_GIT_BASE_URL
Environment variable MINI_BUILDSYS_GIT_BASE_URL specifying base path to your git account.

example: MINI_BUILDSYS_GIT_BASE_URL=git@github.com:tebrevik

### target-config.conf
A simple configuration file where each target repository is specified one per line.

### crontab example:
*/30 * * * * MINI_BUILDSYS_DOCKER_REPO_URL=localhost:34371 MINI_BUILDSYS_GIT_BASE_URL=git@github.com:tebrevik ~/build/run.sh
