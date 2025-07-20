#!/bin/sh

# Run with sudo to add the dev packages required to build from kit. Based on dev-setup.sh from opendnscache

set -e

case $(uname -o) in
GNU/Linux)
    export DEBIAN_FRONTEND=noninteractive

    DISTRO=$(sed -n -e 's/^VERSION_CODENAME=//p' -e 's,^PRETTY_NAME=.*[(/]\([^)"]*\).*,\1,p' /etc/os-release | head -1)

    if [ -z "${DISTRO}" ]; then
        echo "FAILED to determine DISTRO from /etc/os.releases"
        exit 1
    fi

    # Get the list of our packages from the aptly server
    #
    rm -f /etc/apt/sources.list.d/packages_opendns_com_opendns_${DISTRO}.list    # Get rid of any old package config
    apt-get -y install gnupg2 wget                                               # Needed for apt key
    wget -q -O /etc/apt/trusted.gpg.d/opendns-packages-48E8D732.asc http://packages-aptly.opendns.com/opendns/${DISTRO}/opendns-packages-48E8D732.asc

    for repo in dev custom opendns; do
        req="deb http://packages-aptly.opendns.com/opendns/$DISTRO $repo main"

        if ! fgrep -q "$req" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
            PKGCFG=/etc/apt/sources.list.d/packages_aptly_opendns_com_${repo}_${DISTRO}.list
            echo $req > ${PKGCFG}
            echo Subscribed to the $repo repo
        fi
    done

    apt-get -y install ca-certificates # Just in case
    apt-get update
    apt-get -y upgrade

    apt-get -y install build-essential libtap
    ;;

*)
    echo "I don't know what I'm doing" >&2
    exit 1
    ;;
esac

exec libkit/dev-setup.sh $1
