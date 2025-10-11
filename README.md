# redmine-dev

## Overview

This repo contains artifacts to work in the development of redmine plugins

We use docker for our work.

You need a folder structure like this:
```
├── redmine-dev # this folder
├── redmine # clone of a redmine repo
├── some-redmine-plugin1
├── some-redmine-plugin2
├── ... and so on ...
└── ... and so on ...
```
## Buiilding the image
```
./build_image.sh
```

## Start the container
```
./start_container.sh
```
## Prepare mariadb

Once inside the container, at the first time you will need to prepare. Do it this way:
```
./prepare_mariadb.sh
```
This will need to be done only once.

Then exit the container.
```

## Plugin development

Inside the container, you can start a tmux session with mysql connected to mariadb server and redmine running by doing:
```
./tmux_session.sh
```

Then you can access redmine in your browser at:
```
http://localhost:3000/
```

Inside the folder redmine/plugins, add symbolic links to folders of the plugins you are working on and restart redmine (do 'bundle install --path bundle-data' if required by the plugin)
(we use 'bundle install --path bundle-data' instead of just 'bundle install' because this way we will preserve the bundle artifacts and we will not need ot wait for long the next time we start the container).





