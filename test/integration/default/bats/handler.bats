#!/usr/bin/env bats

@test 'creates handler file' {
  [[ -f /tmp/kitchen/handlers/jenkins_handler.rb ]]
}

@test 'handler file has correct mode' {
  [[ `stat -c %a /tmp/kitchen/handlers/jenkins_handler.rb` == '755' ]]
}

@test 'handler file owned by root' {
  [[ `stat -c %U /tmp/kitchen/handlers/jenkins_handler.rb` == 'root' ]]
}

@test 'handler file group is root' {
  [[ `stat -c %G /tmp/kitchen/handlers/jenkins_handler.rb` == 'root' ]]
}

@test 'creates handler report' {
  [[ -f /tmp/chef-handler-jenkins-dryrun.json ]]
}

@test 'handler report has content' {
  [[ `stat -c %s /tmp/chef-handler-jenkins-dryrun.json` -gt 0 ]]
}
