#!/usr/bin/env bash

set -o posix

## This command prepares the fast boot by capturing env vars and args

set -e
set -m

require_cookie

[ -f "$REL_DIR/$REL_NAME.boot" ] && BOOTFILE="$REL_NAME" || BOOTFILE=start
FOREGROUNDOPTIONS="-noshell -noinput +Bd"

# Setup beam-required vars
PROGNAME="${0#*/}"
export PROGNAME

# Store passed arguments since they will be erased by `set`
ARGS="$*"

# Build an array of arguments to pass to exec later on
# Build it here because this command will be used for logging.
set -- "$BINDIR/erlexec" $FOREGROUNDOPTIONS \
    -boot "$REL_DIR/$BOOTFILE" \
    -boot_var ERTS_LIB_DIR "$ERTS_LIB_DIR" \
    -env ERL_LIBS "$REL_LIB_DIR" \
    -pa "$CONSOLIDATED_DIR" \
    -args_file "$VMARGS_PATH" \
    -config "$SYS_CONFIG_PATH" \
    -mode "$CODE_LOADING_MODE" \
    ${ERL_OPTS} \
    -extra ${EXTRA_OPTS}

IFS=$'\n' STARTENV_ARR=($(echo "${STARTENV}"))
unset STARTENV
IFS=$'\n' CURENV=($(printenv | sed -e 's/=/="/' | sed -e 's/$/"/'))

diffenv=()

for i in "${CURENV[@]}"
do
    if [[ ! " ${STARTENV_ARR[@]} " =~ " ${i} " ]]; then
        diffenv+=("${i}")
    fi
done

cat > "$REL_DIR/${REL_NAME}_fast_start.sh" << EOF
#!/usr/bin/env bash
$(for e in "${diffenv[@]}"; do echo "export $e"; done)
exec $@
EOF

chmod +x "$REL_DIR/${REL_NAME}_fast_start.sh"
