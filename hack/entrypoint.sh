#!/bin/bash
# Entrypoint: load asdf profile and, when GitLab runs /bin/sh -c "script",
# re-execute the script in bash so BASH_ENV/profile apply. No before_script needed in jobs.

set -e

source /etc/profile.d/asdf.sh
cd "${CI_PROJECT_DIR:-/code_validation}"
[ -f .tool-versions ] && /installer/add-tools.sh .tool-versions || true

# GitLab Runner invokes the job script as: /bin/sh -c "script".
# Run that script in bash so BASH_ENV (/etc/profile.d/asdf.sh) is applied and asdf shims are in PATH.
if [ "$1" = "/bin/sh" ] && [ "$2" = "-c" ] && [ -n "${3:-}" ]; then
    exec /bin/bash -c "$3"
fi

exec "$@"
