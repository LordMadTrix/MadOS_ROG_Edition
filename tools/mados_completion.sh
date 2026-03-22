# MadOS CLI Bash Completion
_mados_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="shift check update aura batt ai gui help"

    case "${prev}" in
        shift)
            local modes="game eco dev balance"
            COMPREPLY=( $(compgen -W "${modes}" -- ${cur}) )
            return 0
            ;;
        aura)
            local auras="rainbow pulse static off"
            COMPREPLY=( $(compgen -W "${auras}" -- ${cur}) )
            return 0
            ;;
        batt)
            local limits="60 80 100"
            COMPREPLY=( $(compgen -W "${limits}" -- ${cur}) )
            return 0
            ;;
        ai)
            local actions="start stop restart status"
            COMPREPLY=( $(compgen -W "${actions}" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _mados_completion mados
