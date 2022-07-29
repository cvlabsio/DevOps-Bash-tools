#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-07-29 19:15:08 +0100 (Fri, 29 Jul 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Creates Kubernetes sealed secrets from all Kubernetes secrets in the current or given namespace

Iterates all non-service-account-token secrets, and for each one:

    - generates sealed secret yaml
    - annotates existing secret to be able to be managed by sealed secrets
    - creates sealed secret in the same namespace

Useful to migrate existing secrets to sealed secrets which are safe to commit to Git


Requires kubectl and kubeseal to both be in the \$PATH and configured
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<namespace> <context>]"

help_usage "$@"

#min_args 1 "$@"

namespace="${1:-}"
context="${2:-}"

kube_config_isolate

if [ -n "$context" ]; then
    kube_context "$context"
fi
if [ -n "$namespace" ]; then
    kube_namespace "$namespace"
fi

kubectl get secrets |
# don't touch the default generated service account tokens for safety
grep -v kubernetes.io/service-account-token |
# remove header
grep -v '^NAME[[:space:]]' |
awk '{print $1}' |
while read -r secret; do
    yaml="sealed-secret-$secret.yaml"

    timestamp "Generating sealed secret for secret '$secret'"

    kubectl get secret "$secret" -o yaml |
    kubeseal -o yaml > "$yaml"

    timestamp "Generated:  $yaml"

    timestamp "Annotating secret '$secret' to be managed by sealed-secrets controller"

    kubectl annotate secrets "$secret" 'sealedsecrets.bitnami.com/managed="true"' --overwrite

    timestamp "Creating sealed secret '$secret'"

    kubectl apply -f "$yaml"

    echo
done
