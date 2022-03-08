#!/usr/bin/env bash
set -e 


BUILD_PATH=$(dirname $(readlink -f "$0"))
START_DIR=$(pwd)

LOGNAME=${BUILD_PATH}/log/$(/usr/bin/env date "+%FT%H.%M").log
mkdir -p ${BUILD_PATH}/log

if [ -z $MINI_BUILDSYS_DOCKER_REPO_URL ]
then
  echo "docker registry url must be specified in environment variable MINI_BUILDSYS_DOCKER_REPO_URL"
  exit -1
fi

if [ -z $MINI_BUILDSYS_GIT_BASE_URL ]
then
  echo "git base url must be specified in environment variable MINI_BUILDSYS_GIT_BASE_URL"
  exit -1
fi

if [ ! -f ${BUILD_PATH}/target-config.conf ]
then
    echo "target-config.conf does not exist. Specify one target repository to build per line"
    exit -1
fi


build_target() {
    target=$1
    cd ${BUILD_PATH}
    echo "starting build for ${target}" 2>&1 | /usr/bin/env tee --append ${LOGNAME}
    if [ -d ${target} ]
    then
        cd ${target}
        LOCAL_STATE=$(/usr/bin/env git rev-parse @)
        REMOTE_STATE=$(/usr/bin/env git ls-remote --heads 2>/dev/null | /usr/bin/env grep main | /usr/bin/env awk '{split($0,a);print a[1]}') 
        echo "Remote state ${REMOTE_STATE}" 2>&1 | /usr/bin/env tee --append ${LOGNAME}
        echo "Local state ${LOCAL_STATE}"   2>&1 | /usr/bin/env tee --append ${LOGNAME}
        if [ ${LOCAL_STATE} = ${REMOTE_STATE} ]
        then
            echo no changes  2>&1 | /usr/bin/env tee --append ${LOGNAME}
            remote_tag=$(/usr/bin/env git ls-remote --tags 2>/dev/null | /usr/bin/env grep $(git rev-parse HEAD) | /usr/bin/env awk '{split($0,a);split(a[2],b,"/");print b[3];}')
            if [ ! -z ${remote_tag} ]
            then
                if [ -f BUILD_TAGGED ]
                then
                    rm ${LOGNAME} #don't need logfile
                    return 0
                else
		    /usr/bin/env git pull 2>&1 | /usr/bin/env tee --append ${LOGNAME}
                fi
            else 
                    rm ${LOGNAME} #don't need logfile
                    return 0
            fi
        else
            if [ -f BUILD_TAGGED ]
            then
                rm BUILD_TAGGED
            fi
            /usr/bin/env git pull  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        fi
    else
        /usr/bin/env git clone --recursive ${MINI_BUILDSYS_GIT_BASE_URL}/${target}.git  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        cd ${target}
    fi

    if [ $(/usr/bin/env git describe --tags --exact-match 2>/dev/null) ]; then
        tag=$(/usr/bin/env git describe --tags)
    else
        tag="notag"
    fi

    if [ ${tag} == "notag" ]
    then
        echo "building unversioned build"  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        /usr/bin/env docker build -t $1 .  2>&1 | /usr/bin/env tee --append ${LOGNAME}
    else
        echo "building version: ${tag}"  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        /usr/bin/env docker build -t ${MINI_BUILDSYS_DOCKER_REPO_URL}/$1:${tag} .  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        /usr/bin/env docker push ${MINI_BUILDSYS_DOCKER_REPO_URL}/$1:${tag}  2>&1 | /usr/bin/env tee --append ${LOGNAME}
        touch BUILD_TAGGED
    fi
}

#process each build target repository specified in target-config.conf
for t in $(cat ${BUILD_PATH}/target-config.conf)
do
  build_target $t
done

#return to where we was when we started the build
cd ${START_DIR}
