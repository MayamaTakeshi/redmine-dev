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
## Prepare databse

Once inside the container run
```
./prepare_db.sh 
```
This will need to be done everytime you start the container unless you mount a host folder to keep the maridbdb server files

After the above completes you can start redmine by doing:
```
cd ../redmine
bundle exec rails server -e development
```

## Plugin development

Inside the folder redmine/plugins, add symbolic links to folders of the plugins you are working on and restart redmine.




