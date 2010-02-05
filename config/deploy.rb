set :application, "feeds"
set :repository,  "git://github.com/phillmv/thesis.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
set :scm, :git

set :scm_command, "/usr/bin/git"
set :deploy_via, :remote_cache

ssh_options[:forward_agent] = true

role :app, "okayfail.com"
role :web, "okayfail.com"
role :db,  "okayfail.com", :primary => true
