#! shell_control.sh

show()
{
    # usage: show [-i|-r] <message>
    # -i: show an important message
    # -r: show a command that will be run
    local important=0
    if [[ "$1" == "-i" ]]; then
        shift
        important=1
        echo -n $'\e[38;5;196m'"$(tput bold)! "
    elif [[ "$1" == "-r" ]]; then
        shift
        echo -n $'\e[38;5;40m$\e[38;5;63m '
    else
        echo -n $'\e[1;34m>\e[0m\e[31m '
    fi

    echo -n "$1"

    if [[ "$important" == "1" ]]; then
        echo -n " $(tput sgr0)"$'\e[0m'
    else
        echo -n $'\e[0m'
    fi

    echo
}

run()
{
    # usage: run <command>; SC_DRYRUN=1 means command will not actually be run
    show -r "$1"
    if [[ $SC_DRYRUN == 0 ]]; then
        eval "$1"
        return $?
    else
        return 0
    fi
}

abort()
{
    # usage: abort <message> [cleanup command]
    if [[ -n "$2" ]]; then
        run "$2"
    fi
    echo $'\e[1;31merror:' "$1" $'\e[0m' >&2
    exit 1
}

ask()
{
    # usage: ask "question"; SC_FORCE=1 implies reply is yes
    if [[ $SC_FORCE = 1 ]]; then
        REPLY='y'
        return 0
    fi
    echo -n $'\n\e[1;35m'
    read -p "$1 (y/n) [n] ... "
    echo -n $'\e[0;0m'
}

query()
{
    # usage: query "question" [fallback]; SC_FORCE=1 implies reply is fallback
    if [[ $SC_FORCE = 1 ]]; then
        REPLY="$2" # fallback used
        return 0
    fi
    echo -n $'\n\e[1;35m'
    read -p "$1 ... "
    echo -n $'\e[0;0m'
}

export SC_DRYRUN=0
export SC_FORCE=0
