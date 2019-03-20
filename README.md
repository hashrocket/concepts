# Concepts

A gallery for our side projects.

### Setup

To build the app with stubbed data:

```
$ git clone git@github.com:hashrocket/concepts.git
$ cd concepts/react
$ npm install
$ npm start
```

View the app at http://localhost:3000.

### Test

```
$ cd react
$ npm test
```

### Deploy

```
$ rsync -avz -e "ssh -F /Users/dev/.ssh/config" --exclude='/.git' --filter="dir-merge,- .gitignore" . concepts@do_lotho_concepts:~/
$ ssh do_lotho_concepts -C "./post_rsync.sh"
```

### The `.hrconcept` File

You can add a project to *Concepts* by adding an `.hrconcept` file to the root
directory of your project in GitHub. *Concepts* will iterate through each public
repo of members of the GitHub Hashrocket organization looking for this file.

`.hrconcept` is a YAML file that looks like this:

``` yaml
name: triangles
url: https://chris-triangles.herokuapp.com
banner: true
description: |
  A place to play with triangles
technologies:
  - SVG
  - React
```

Here are the fields `.hrconcept` supports:

* name - (string) The title you'd like to display for your project.  It will
  default to a titleized version of the repository name.
* url - (string) The url for your application.  It will default to the GitHub
  repo url.
* banner - (true|false) When set to true *Concepts* will inject a branded
  banner into your site. Defaults to true.
* description - (string) A short description of your project displayed on the
  index page, defaults to the GitHub project description.
* technologies - (array) A list of technologies in the project that you'd like
  to highlight, defaults to GitHub's [Linguist][linguist-repo] language evaluation.

[linguist-repo]: (https://github.com/github/linguist)
