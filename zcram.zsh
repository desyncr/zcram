#!/usr/bin/zsh
# vim: tabstop=4 shiftwidth=4 expandtab
#setopt extended_glob
-zcram-test-command () {
    local expected=$1
    local result=$2
    expected=$(echo "$expected"|sed 's/    //')
    -show-error () {
        echo "FAIL"
        echo "Result   : $2"
        echo "Expected : $1"
    }

    if [[ "$expected" =~ "(re)" ]]; then
        expected=$(echo "$expected"|sed 's/\s(re)//')
        echo "$result" | grep -q "$expected"
        if [[ $? == 1 ]]; then
            -show-error "$expected" "$result"
        fi
    else
        if [[ "$expected" != "$result" ]]; then
            -show-error "$expected" "$result"
        fi
    fi
}

BUFFER_EXPECTED=
BUFFER_COMMAND=
BUFFER_RESULT=
cat $1 | while IFS= read -r line
do
    # Expected result
    if [[ $(echo "$line" | grep '    \w') ]]; then
        if [[ "$BUFFER_EXPECTED" != "" ]]; then
            BUFFER_EXPECTED+="\n"
        fi
        BUFFER_EXPECTED+=$(echo "$line"|sed 's/    //'|awk '{$1=$1};1')
    else
        if [[ $BUFFER_EXPECTED != "" ]]; then
            echo "--"
            echo $BUFFER_COMMAND
            echo "--"
            BUFFER_RESULT=$(eval $BUFFER_COMMAND)
            -zcram-test-command $BUFFER_EXPECTED $BUFFER_RESULT
            BUFFER_EXPECTED=""
            BUFFER_RESULT=""
        fi

        # Command
        if [[ $(echo "$line" | grep '$ .*') ]] then
            echo "$line"
            BUFFER_COMMAND+=$(echo "$line"|sed 's/\$\s//'|awk '{$1=$1};1')

        # Command continution
        elif [[ $(echo "$line" | grep '>.*') ]] then
            echo "$line"
            BUFFER_COMMAND+="\n"$(echo "$line"|sed 's/>\s//'|awk '{$1=$1};1')

        # Ignore blank lines
        elif [[ "$line" == "" ]]; then
            echo ""
        # Print everything else
        else
            echo "$line"
        fi
    fi
done
echo ""
