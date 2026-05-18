# MadOS CLI Bash Completion

_mados_completions() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="shift aura batt ai vr night status doctor check clean temps kernel logs guide store snapshot update uninstall help"

    case "${prev}" in
        shift)
            COMPREPLY=( $(compgen -W "game eco balance" -- "${cur}") )
            return 0
            ;;
        aura)
            COMPREPLY=( $(compgen -W "rainbow pulse static off" -- "${cur}") )
            return 0
            ;;
        batt)
            COMPREPLY=( $(compgen -W "60 80 100" -- "${cur}") )
            return 0
            ;;
        ai)
            COMPREPLY=( $(compgen -W "start stop status" -- "${cur}") )
            return 0
            ;;
        vr)
            COMPREPLY=( $(compgen -W "start" -- "${cur}") )
            return 0
            ;;
        logs)
            COMPREPLY=( $(compgen -W "--errors --follow grep" -- "${cur}") )
            return 0
            ;;
        night)
            COMPREPLY=( $(compgen -W "on off" -- "${cur}") )
            return 0
            ;;
        store)
            COMPREPLY=( $(compgen -W "steam discord heroic lutris bottles obs nvtop" -- "${cur}") )
            return 0
            ;;
        static)
            COMPREPLY=( $(compgen -W "-c" -- "${cur}") )
            return 0
            ;;
        -c)
            # Couleurs ROG prédéfinies (RRGGBB)
            local colors="ff003c ff0000 ff8800 ffff00 00ff00 00ff88 00ffff 0080ff 8000ff ff00ff ffffff 000000"
            COMPREPLY=( $(compgen -W "$colors" -- "${cur}") )
            return 0
            ;;
        *)
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
    return 0
}

complete -F _mados_completions mados
