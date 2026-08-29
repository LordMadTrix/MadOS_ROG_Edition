# Auto-complétion Bash pour l'utilitaire « mados ».
# Installée vers /etc/bash_completion.d/mados par modules/28_mados_cli.sh.
# Les listes ci-dessous doivent rester alignées sur le case final de tools/mados.sh.

_mados_completion() {
    local cur prev commandes
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commandes="shift status health update night boost backups restore version help"

    # Premier mot : la sous-commande.
    if [ "$COMP_CWORD" -eq 1 ]; then
        mapfile -t COMPREPLY < <(compgen -W "$commandes" -- "$cur")
        return 0
    fi

    # Deuxième mot : l'argument attendu par la sous-commande.
    case "$prev" in
        shift)
            mapfile -t COMPREPLY < <(compgen -W "game balance eco" -- "$cur")
            ;;
        night|boost)
            mapfile -t COMPREPLY < <(compgen -W "on off" -- "$cur")
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
    return 0
}

complete -F _mados_completion mados
