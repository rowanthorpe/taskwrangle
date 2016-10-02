Taskwrangle
===========

Copyright/License
-----------------

Copyright © 2016 Rowan Thorpe. Initially based entirely on a `taskdb` demo-app
posted by Joe Bognor at [the Picolisp wiki](http://picolisp.com/wiki/?taskdb)
on 24 August 2016, and has been developed extensively from there. As best as I
could ascertain by enquiring, that blog post either falls under Public Domain,
or the MIT license (I didn't receive a conclusive answer yet). Either way this
usage is covered. I will add appropriate copyright-header for that content
if/when I receive a clearer answer about that.

Taskwrangle is distributed under the terms of the [GNU Affero General Public
License](https://www.gnu.org/licenses/agpl-3.0.html) version 3 or greater.

Installation
------------

Copy `conf/taskwrangle.l.template` to `conf/taskwrangle.l` and edit the copied
file to suit your needs, then run `./install.sh`. To toggle un/install-mode or
customize installation locations use flags (see `./install.sh -h` for details)
or for greater control edit `./install.sh` directly.

Rationale
---------

I was frustrated by various task-management systems I gave up on over the years
(mainly due to them being over-engineered for my needs, and my never having the
time to become a "task-management guru" just to have a hierarchical TODO
system). From those experiences and some good takeaways from working with
trouble-ticket and project-management systems over the years, I know very much
what I want in a personal task-management system, and more importantly - what I
*don't* want. For that reason, when Joe Bognor posted a mini task-management
demo-app on the Picolisp site I got enthusiastic while playing with it and
developed it to the point that I found useful as a real-world app. For the sake
of getting input from others (and in case anyone else would like to use it)
I've uploaded it.
