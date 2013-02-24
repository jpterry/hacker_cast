require "bundler/capistrano"

set :application, "mepeer"
set :repository,  "git@github.com:jpterry/hacker_cast.git"

set :branch, "master"
set :ssh_options, { :forward_agent => true }

set :deploy_via, :remote_cache
# set :scm, :git # You can set :scm explicitly or Capistrano will make an intelligent guess based on known version control directory names
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "mepeer.com"                          # Your HTTP server, Apache/etc
role :app, "mepeer.com"                          # This may be the same as your `Web` server
set  :deploy_to, "/srv/mepeer"
set :default_environment, {
  'PATH' => '/opt/rbenv/shims:/opt/rbenv/bin:$PATH'
}

#role :db,  "your primary db-server here", :primary => true # This is where Rai ls migrations will run
#role :db,  "your slave db-server here"

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end
