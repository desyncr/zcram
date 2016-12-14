#!/usr/bin/zsh
# vim: tabstop=4 shiftwidth=4 expandtab
#setopt extended_glob
STOP_ON_ERROR=true

-zcram-test-command () {
    local expected=$1
    local result=$2
    local testblock=$3
    local result_code=$4

    expected=$(echo "$expected"|sed 's/    //')
    -show-error () {
        echo "FAIL     : $testblock"
        echo "Result   : '$result'"
        echo "Result Code: '$result_code'"
        echo "Expected : '$expected'"
    }

    if [[ "$expected" =~ "(re)" ]]; then
        expected=$(echo "$expected"|sed 's/\s(re)//')
        echo "$result" | grep -q "$expected"
        if [[ $? == 1 ]]; then
            -show-error "$expected" "$result"
            [[ $STOP_ON_ERROR ]] && exit
        fi
    elif [[ "$expected" =~ '\[.*' ]]; then
        expected=$(echo "$expected"|sed -e 's/\[//' -e 's/\]//')
        echo "$result_code" | grep -q "$expected"
        if [[ $? == 1 ]]; then
            -show-error "$expected" "$result_code"
            [[ $STOP_ON_ERROR ]] && exit
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
BUFFER_TESTBLOCK=
cat $1 | while IFS= read -r line
do
    # Expected result
    if [[ $(echo "$line" | grep '^    [^$>]') ]]; then
        if [[ "$BUFFER_EXPECTED" != "" ]]; then
            BUFFER_EXPECTED+="\n"
        fi
        BUFFER_EXPECTED+=$(echo "$line"|sed 's/    //'|awk '{$1=$1};1')
    else
        if [[ $BUFFER_EXPECTED != "" ]]; then
            #echo "--"
            #echo $BUFFER_COMMAND
            #echo "--"
            BUFFER_RESULT=$(eval $BUFFER_COMMAND)
            BUFFER_RESULT_CODE=$?
            -zcram-test-command "$BUFFER_EXPECTED" "$BUFFER_RESULT" "$BUFFER_TESTBLOCK" "$BUFFER_RESULT_CODE"
            BUFFER_EXPECTED=""
            BUFFER_RESULT=""
        fi

        # Command
        if [[ $(echo "$line" | grep -e '^    $ .*') ]] then
            #echo "Command: $line"
            BUFFER_COMMAND+=$'\n'$(echo "$line"|sed 's/\$\s//'|awk '{$1=$1};1')

        # Command continution
        elif [[ $(echo "$line" | grep -e '^    > .*') ]] then
            #echo "$line"
            BUFFER_COMMAND+=$'\n'$(echo "$line"|sed 's/>//'|awk '{$1=$1};1')

        # Ignore blank lines
        elif [[ "$line" == "" ]]; then
        elif [[ $(echo "$line" | grep '#.*') ]]; then
            #echo "Ignoring: $line"
#            echo ""
        # Print everything else
        else
#            echo "$line"
            BUFFER_TESTBLOCK=$line
            BUFFER_COMMAND=""
#            echo "$line"
        fi
    fi
done
echo ""
