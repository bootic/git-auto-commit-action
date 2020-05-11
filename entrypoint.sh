#!/bin/bash

set -eu

_main() {
    _switch_to_repository

    if _git_is_dirty; then

        echo "::set-output name=changes_detected::true";

        _switch_to_branch

        _add_files

        if _git_is_actually_dirty; then
            _local_commit

            _tag_commit

            _push_to_github
        else
            echo "::set-output name=changes_detected::false";
            echo "Working tree clean. Nothing to commit.";
        fi
    else

        echo "::set-output name=changes_detected::false";

        echo "Working tree clean. Nothing to commit.";
    fi
}


_switch_to_repository() {
    echo "INPUT_REPOSITORY value: $INPUT_REPOSITORY";
    cd $INPUT_REPOSITORY;
}

_git_is_actually_dirty() {
    [ -n "$(git status -s)" ]
} 

# This is almost always true with ignored enabled
# 魔改代码
_git_is_dirty() {
    [ -n "$(git status -s --ignored)" ]
}

_switch_to_branch() {
    echo "INPUT_BRANCH value: $INPUT_BRANCH";

    # Switch to branch from current Workflow run
    git checkout $INPUT_BRANCH;
}

_add_files() {
    echo "INPUT_FILE_PATTERN: ${INPUT_FILE_PATTERN}";
    echo "INPUT_ADD_OPTIONS: ${INPUT_ADD_OPTIONS}";
    echo "::debug::Apply add options ${INPUT_ADD_OPTIONS}";
    INPUT_ADD_OPTIONS_ARRAY=( $INPUT_ADD_OPTIONS );


    git add ${INPUT_FILE_PATTERN} \
        ${INPUT_ADD_OPTIONS:+"${INPUT_ADD_OPTIONS_ARRAY[@]}"};
}

_local_commit() {
    echo "INPUT_COMMIT_OPTIONS: ${INPUT_COMMIT_OPTIONS}";
    echo "::debug::Apply commit options ${INPUT_COMMIT_OPTIONS}";

    INPUT_COMMIT_OPTIONS_ARRAY=( $INPUT_COMMIT_OPTIONS );

    git -c user.name="$INPUT_COMMIT_USER_NAME" -c user.email="$INPUT_COMMIT_USER_EMAIL" \
        commit -m "$INPUT_COMMIT_MESSAGE" \
        --author="$INPUT_COMMIT_AUTHOR" \
        ${INPUT_COMMIT_OPTIONS:+"${INPUT_COMMIT_OPTIONS_ARRAY[@]}"};
}

_tag_commit() {
    echo "INPUT_TAGGING_MESSAGE: ${INPUT_TAGGING_MESSAGE}"

    if [ -n "$INPUT_TAGGING_MESSAGE" ]
    then
        echo "::debug::Create tag $INPUT_TAGGING_MESSAGE";
        git -c user.name="$INPUT_COMMIT_USER_NAME" -c user.email="$INPUT_COMMIT_USER_EMAIL" tag -a "$INPUT_TAGGING_MESSAGE" -m "$INPUT_TAGGING_MESSAGE";
    else
        echo " No tagging message supplied. No tag will be added.";
    fi
}

_push_to_github() {
    if [ -z "$INPUT_BRANCH" ]
    then
        # Only add `--tags` option, if `$INPUT_TAGGING_MESSAGE` is set
        if [ -n "$INPUT_TAGGING_MESSAGE" ]
        then
            echo "::debug::git push origin --tags";
            git push origin --tags;
        else
            echo "::debug::git push origin";
            git push origin;
        fi

    else
        echo "::debug::Push commit to remote branch $INPUT_BRANCH";
        git push --set-upstream origin "HEAD:$INPUT_BRANCH" --tags;
    fi
}

_main
