Octoherder
----------

Because everyone needs a little help herding their octocats.

[![Build Status](https://secure.travis-ci.org/frankshearar/octoherder.png?branch=master)](http://travis-ci.org/frankshearar/octoherder) [![Coverage Status](https://coveralls.io/repos/frankshearar/octoherder/badge.png?branch=master)](https://coveralls.io/r/frankshearar/octoherder)

So what's it for?
-----------------

If you have multiple repositories for one project, it's a pain to manage the project. Sure, huboard gives you a kanban board across your repositories, but you still have to add the columns and milestones to your various repositories. And what happens when you need to change an existing milestone? Octoherder lets you define your canonical set of milestones and labels, and ensures that all your repositories have the same setup.

How do I use it?
----------------

First decide what your master repository will be. If you're a huboard user, choose the repository that holds the `Link <=> other/repo` labels. Octoherder will use this information during its setup.

__Everything below here is vapourware!__
Run `octoherder -o definitions.yml -r master/repo`. That will produce a YAML file looking something like this:

````yaml
---
master: me/master-repo

repositories:
  - me/sub-repo
  - other/sub-repo2

milestones:
  - title: milestone-1
    state: closed
  - title: milestone-2
    due_on: 2011-04-10T20:09:31Z
  - title: milestone-3
    state: open
    description: The third step in total world domination.

columns:
  - 0 - Backlog
  - 1 - Ready
  - 2 - Working
  - 3 - QA
  - 4 - Done
````

Adjust your milestones as necessary, and update your repositories with their new milestones with `octoherder -f definitions.yml`. Done!

Licence
-------

Copyright (C) 2013 by Frank Shearar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.