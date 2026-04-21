if [[ -x $(which terramate) ]] then
    complete -o nospace -C terramate terramate
fi
