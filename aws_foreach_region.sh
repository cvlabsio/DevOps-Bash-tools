#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#  args: echo region is {region}'
#
#  Author: Hari Sekhon
#  Date: 2021-07-19 14:59:58 +0100 (Mon, 19 Jul 2021)
#
#  https://github.com/harisekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Run a command against each AWS region in the current account

You may want to use this to run an AWS CLI command against all regions to find resources or perform scripting across regions

This is powerful so use carefully!

Requires AWS CLI to be installed and configured and 'aws' to be in the \$PATH

All arguments become the command template

The following command template tokens are replaced in each iteration:

Project ID:     {region}

eg.
    ${0##*/} 'echo AWS region is {region}'
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="<command> <args>"

help_usage "$@"

min_args 1 "$@"

cmd_template="$*"


aws ec2 describe-regions |
jq -r '.Regions[] | .RegionName' |
while read -r region; do
    echo "# ============================================================================ #" >&2
    echo "# AWS region = $region" >&2
    echo "# ============================================================================ #" >&2
    export AWS_DEFAULT_REGION="$region"
    cmd="$cmd_template"
    cmd="${cmd//\{region\}/$region}"
    eval "$cmd"
    echo >&2
    echo >&2
done
