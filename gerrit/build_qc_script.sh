#!/bin/bash -el

WORKSPACE=`pwd`
op_argument=("$@")
host_name=${op_argument[0]}
amss_branch=${op_argument[1]}
android_branch=${op_argument[2]}
git_ssh_user=${op_argument[3]}
amss_changes=${op_argument[4]}
android_change=${op_argument[5]}


cherry_pick_changes(){
  host=$1
  path=$2
  changes=$3
  user=$4
  echo "cherry_pick_changes : $host, $path, $changes, $user"

  cd $path
  IFS=',' read -ra changes <<< "$changes"
  for change in "${changes[@]}"; do
    if [[ $change == -* ]]; then
      revert="y"
      change=${change:1}
    else
      revert="n"
    fi
    info=`ssh -p 29418 ${user}@${host} gerrit query change:$change --format json --current-patch-set | jq -r 'select(.project != null) | .project + "," + .currentPatchSet.ref + "," +.currentPatchSet.revision'`
    if [ -n "$info" ]; then
      proj=`echo $info | cut -d',' -f1`
      ref=`echo $info | cut -d',' -f2`
      sha1=`echo $info | cut -d',' -f3`
      mpath=`repo info $proj | grep path | cut -d':' -f2`
      cd $mpath
      git config user.name ${user}
      git config user.email ${user}@arimacomm.com.tw
      if [ "$revert" == "y" ]; then
        git revert --no-edit --strategy=recursive --strategy-option=theirs $sha1
        rc=$?
        if [ $rc -gt 1 ]; then
          exit $rc
        fi
      else
        git fetch git://${host}/$proj $ref
        git cherry-pick --allow-empty --no-edit --strategy=recursive --strategy-option=theirs FETCH_HEAD
        rc=$?
        if [ $rc -eq 1 ]; then
          git commit --no-edit --allow-empty
        elif [ $rc -gt 1 ]; then
          exit $rc
        fi
      fi
    else
      echo "change $change not found"
      exit 1
    fi
  done
}

link_file_to_root(){
  linkarray=("$@")
  path=${linkarray[0]}
  echo "link_file_to_root : ${linkarray[@]}"

  cd $path
  for ((i=1; i < ${#linkarray[@]}; i++))
    do
      [ -f ${linkarray[$i]} ] && ln -sv ${linkarray[$i]} ./ || echo "Cannot find $path/${linkarray[$i]}"
    done
}

amsslink=("root_dir/build.gradle" "root_dir/create_android.py" "root_dir/gradle.properties" "root_dir/image_packing.py" "root_dir/setenv.sh" "root_dir/settings.gradle")
cherry_pick_changes "${host_name}" "${WORKSPACE}/amss" "${amss_changes}" "${git_ssh_user}"
link_file_to_root "${WORKSPACE}/amss" "${amsslink[@]}"

androidlink=("build/make/core/copy/build.gradle")
cherry_pick_changes "${host_name}" "${WORKSPACE}/android" "${android_change}" "${git_ssh_user}"
link_file_to_root "${WORKSPACE}/android" "${androidlink[@]}"
