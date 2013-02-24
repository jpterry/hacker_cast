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

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd #{current_path} && sudo bundle exec foreman export upstart /etc/init " +
        "-f ./Procfile.prod -a #{application} -u nobody -l #{shared_path}/log"
  end

  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end

  desc "Display logs for a certain process - arg example: PROCESS=web-1"
  task :logs, :roles => :app do
    run "cd #{current_path}/log && cat #{ENV["PROCESS"]}.log"
  end
end

namespace :deploy do
  task :start do
    run "cd #{current_path}; bundle exec foreman -f Procfile.prod start"
  end
  task :stop do
    run "cd #{current_path}; bundle exec foreman -f Procfile.prod stop"
  end
  task :restart do
    #run "cd #{current_path}; bundle exec foreman -f Procfile.prod restart"
  end
end
