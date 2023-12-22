class DigitalspaceGitSsh < Formula
  url "file:///dev/null"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "0.1.10"

  def git_ssh_script
    <<~EOS
    #!/bin/bash
    SSH_KEY_ARG=""
    if echo $@ | grep -i '[A-Za-z0-9_\\-]\\+@[A-Za-z0-9_\\-\\.]\\+' > /dev/null; then
      REPO_HOST_NAME=$(echo $@ | awk '{print tolower($0)}' | grep -o '[A-Za-z0-9_\\-]\\+@[A-Za-z0-9_\\-\\.]\\+' | grep -o '[A-Za-z0-9_\\-\\.]\\+$' | sed "s/[^[:alnum:]-]/_/g")
      REPO_GROUP_NAME=$(echo "${@: -1}" | grep -o '[A-Za-z0-9_-]\\+\\/[A-Za-z0-9_-]\\+' | awk -F\\/ '{ print $1 }' | sed "s/[^[:alnum:].-]/_/g")
      REPO_GROUP_NAME_LOWER=$(echo $REPO_GROUP_NAME | awk '{print tolower($0)}')
      REPO_NAME=$(echo "${@: -1}" | grep -o '[A-Za-z0-9_-]\\+\\/[A-Za-z0-9_-]\\+' | awk -F\\/ '{ print $2 }' | sed "s/[^[:alnum:].-]/_/g")
      REPO_NAME_LOWER=$(echo $REPO_NAME | awk '{print tolower($0)}')
      if [[ -f $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME}_${REPO_NAME} ]]; then
        SSH_KEY_ARG="-i $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME}_${REPO_NAME} -o IdentitiesOnly=yes";
      elif [[ -f $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME} ]]; then
        SSH_KEY_ARG="-i $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME} -o IdentitiesOnly=yes";
      elif [[ -f $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME_LOWER}_${REPO_NAME_LOWER} ]]; then
        SSH_KEY_ARG="-i $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME_LOWER}_${REPO_NAME_LOWER} -o IdentitiesOnly=yes";
      elif [[ -f $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME_LOWER} ]]; then
        SSH_KEY_ARG="-i $HOME/.ssh/id_rsa_${REPO_HOST_NAME}_${REPO_GROUP_NAME_LOWER} -o IdentitiesOnly=yes";
      fi
    fi

    if [[ $SSH_KEY_ARG != "" ]]; then
        >&2 echo "[git-ssh] Additional arguments will be used: $SSH_KEY_ARG"
    fi

    exec ssh $SSH_KEY_ARG "$@"
    EOS
  rescue StandardError
      nil
  end

  def install
    (buildpath / "bin" / "git-ssh").write(git_ssh_script)
    (buildpath / "bin" / "git-ssh").chmod(0755)
    bin.install "bin/git-ssh"
  end

end