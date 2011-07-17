..
.. Module Name: guide.inc
..
.. source include file for the INF file providing help for makefile
..
.. Unlike the nepmd.inf, the makefile.inf is compiled to the bin subdirectory
.. and checked in to make it always available right after checking out.
..
.. So when updating this file, commit also the changed INF file!
..
.. Copyright (c) Netlabs EPM Distribution Project 2002
..
.. $Id$
..
.. ===========================================================================
..
.. This file is part of the Netlabs EPM Distribution package and is free
.. software.  You can redistribute it and/or modify it under the terms of the
.. GNU General Public License as published by the Free Software
.. Foundation, in version 2 as it comes in the "COPYING" file of the
.. Netlabs EPM Distribution.  This library is distributed in the hope that it
.. will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
.. of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
.. General Public License for more details.
..
.. ***************************************************************************


.. =============================================================================
.2 Archive guidelines
.. =============================================================================
.an IDPNL_CVSGUIDE
.
[=TOPICS]
.su V30

.. -----------------------------------------------------------------------------
.3 Using the GNU headers
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_GNUHEADER
.
All non-binary source files are to include a GNU header at its top in the
comment style according to the filetype. There are header templates
for for all currently used filetypes in subdirectory [.IDPNL_DEVTREE src\header].
.
.
As *CVS* cannot handle true OS/2 filetypes, types are determined by filename extensions only.
.
.
When you insert a header template into a file
.ul compact
- add the module name (with parameters, if applicable)
- enter a description in between the line *Module Name* and the Copyright line.

[=NOTE]
.ul compact
.at fc=red
- If a header file for a given file type does not exist, and you want to
commit a file of that type to the archive, *you are responsible*
.at fc=red
to add an appropriate file to the *src\header*
.at fc=red
directory:
.at
.ol compact
   - create a copy of an existing template with the new filename extension
   - modify it to your needs
   - test it with the new source file first
   - commit the new template to the archive.
.el
.el

.. -----------------------------------------------------------------------------
.3 Adding new files to the archive
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_ADDNEW
.
When adding source files to the [=TITLE] archive, please comply to the following
rules when committing a file for the very first time:

.ul compact
- If you are about to add a *modified version* of a source created by someone
  else (e.g. the EPMBBS package), proceed as follows
.ol compact
- Add the _*original*_ version of the file to the archive. This original file
    should not be modified at all (e.g. do not add the appropriate
    [.IDPNL_CVSGUIDE_GNUHEADER GNU header] yet.)
- Commit with comment *First revision*
- Insert the *GNU header* at the top of the original file. (See [.IDPNL_CVSGUIDE_GNUHEADER GNU Headers]
  for more information.)
- Commit with comment *Added GNU header*
- Make you modifications to the file
- Commit your modified version as first update to the archive
.el
- If you are about to add a *completely new file*
.ol compact
  - Insert the appropriate *GNU header* at the top of your file. (See [.IDPNL_CVSGUIDE_GNUHEADER GNU Headers]
  for more information.)
  - Commit with comment *First revision*
.el


.. -----------------------------------------------------------------------------
.3 Write meaningful commit comments
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_COMCOMMENTS
.
The title says it all: try not to write too little or too much.
Moreover, don't write what you changed (example: changed sixth parameter to DosOpen)
but what you intended with the change (example: let access to file fail if it exists).

Commit changes as often as possible in order to keep the changelog short! (See also
very important section [.IDPNL_CVSGUIDE_SMALLUNITS] ).

If you commit changes, please always layout the commit comment as a bullet list.
To make the changelog look better, even include a bullet when there is only one
list item. For example the following is an edited excerpt of a log:
.fo off
----------------------------
revision 1.8
date: 2002/04/22 14:44:29;  author: cla;  state: Exp;  lines: +7 -10
- moved files of current package NEPMD "Netlabs Distribution Extensions"
  into package "Base Application"
  .
  .
  .
----------------------------
revision 1.3
date: 2002/04/18 17:01:36;  author: cla;  state: Exp;  lines: +5 -5
- corrected GNU header
----------------------------
revision 1.2
date: 2002/04/16 21:21:00;  author: cla;  state: Exp;  lines: +15 -9
- changed INFDIR to netlabs\book (former directory: book)
- reordered packages speech and samples (mismatched compared to prepare.cmd)
- created new package NEPMD__BOOK, moved nepmd.inf to this package
----------------------------
.fo on

[=NOTE]
.ul compact
- For revision 1.2 I added three topics with a minus sign bullet
- For revision 1.3 I committed only one modification, but still included
  a bullet to keep the layout
- For revision 1.8 I also committed only one modification and also
  here included a bullet. Furthermore I kept the layout across lines.

.. -----------------------------------------------------------------------------
.3 Start clean away
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_STARTCLEAN
.
It is good practice to start every modification task either with
.ul compact
- a clean working directory (well, at least this is easy as long the
  [=TITLE] archive is that small)
- an updated working directory. When calling *cvs co .* in your working
  directory,
  - no line should be preceded by a *?* except for
    - Directories: compile, epm.packages, zip, release, debug
    - Files: mysetenv.cnd
  - no filename should be proceeded by a *M*, meaning that still a modified
  version of the file is sitting on your hardfile
  (then it is time to "clean up")

Then make your modifications and commit your work. (See [.IDPNL_CVSGUIDE_WORKINGCODE].)

After committing files, it is good practice to finish work with an update operation *cvs co .*
This helps you to make sure that all your code changes have been
committed to the archive. Don't leave uncommitted code on you hardfile any
longer as necessary, or you run into merge operations.

..If you fear to commit non-working code though, either
...ul compact
..- you did not plan your work well  or
..- your modification task may be too large or take too much time to code or test
..  for a normal development cycle. So you may need a [.IDPNL_CVSGUIDE_BRANCHES CVS branch]
..  in order to develop separately from the  main development path. But using branches
..  to separate different development paths are mostly used on large *CVS* archives
..  only, likely the [=TITLE] archive is yet too small to really require this...

.. -----------------------------------------------------------------------------
.3 Commit working code only
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_WORKINGCODE
.
.ul
- *DO NOT COMMIT CODE THAT WILL NOT COMPILE!*
- It is also very bad practice to commit code which compiles but does not work to the archive.
If this is unavoisable or if you are not sure how well your code works, do one or more of the following:
.ul compact
   - comment out or *##ifdef* the code you are not sure about
   - tell project members via email
   - note possible side effects in the comment log
.el
.el

.. -----------------------------------------------------------------------------
.3 Commit every small changes and/or fast (small units of work)
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_SMALLUNITS
.
In order to allow somebody else (or even yourself after some time) to figure
out what changes have been committed to the archive, check in as often and as
frequently as possible. This requires that you separate tasks from each other.
As a side benefit of doing this, merge operations will be avoided.

So commit little changes and commit frequently, or at least one
of that. This is called having *small units of work*.

A good rules of thumb:
.ul compact
- Commit as few modifications together as possible. If two modification tasks
  (not code changes!) can be logically separated from each other, commit separately!
- If one modification requires changes to several files, commit them together.
  - This will result in all changed files appearing in one entry of the change log
    (even committing different files with the same change comment in separate steps will
    result in several change log entries due to the different timestamp).
  - As a positive side effect of this, you will restrict your units of work to the
    modification tasks which concern all the files checked in together.
- If you make changes to only one file, you may commit changes for several
  modification tasks at a time, resulting in multiple items within the commit comment.
  - This should be avoided unless the changes can be considered a "unit".

In summary:
.ul compact
- get the last revision (or last revision of desired branch) of all files
- make the changes for a given modification
- test the modifications
- commit all modified files in one step, writing a meaningful commit comment.

.. -----------------------------------------------------------------------------
.3 Do not create branches
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_BRANCHES
.
*CVS* branches are mostly used when
.ul compact
- shipping a release, allowing fixes on the release version without affecting
  the latest development version
- making modifications to base modules of a product that require so much
  time (let's say weeks) that you will definitely run into merge operations
  (see also section [.IDPNL_CVSGUIDE_SMALLUNITS])

It is project policy that
.ul compact
- generally only the release maintainer is to create branches for releases
- as long as the [=TITLE] archive has no basic module requiring larger development
  cycles, no branches are required
- if you ever think you require branches, request them from the release maintainer.

*DON'T CREATE BRANCHES YOURSELF!*

.. -----------------------------------------------------------------------------
.3 How to ship a release
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_RELEASE
.
This is done by the release maintainer only, but stated here to give
everybody an overview. A release is packed as follows:
.ul compact
- the working directory is cleaned up
- the current tip revision is checked out
- a new branch for the release is created
- the file revisions of that branch are marked with a release label
  in order to checkout a complete release later on
- the package is built and tested
- if necessary, the release maintainer creates
  [.IDPNL_CVSGUIDE_FIXRELEASE fixes for the release],
  if possible (else in cooperation with the responsible developer)
- the resulting package is previewed by selected developers
- the package is shipped

.. -----------------------------------------------------------------------------
.3 How to apply a fix to a release
.. -----------------------------------------------------------------------------
.an IDPNL_CVSGUIDE_FIXRELEASE
.
This is done by the release maintainer and a developer, if required.
A release fix is applied as follows:
.ul compact
- the working directory is cleaned up
- the release version is checked out
- the fix is applied and tested
- the package is built and tested
- the release maintainer moves the revision label of the affected files
  forward to the fix revision
- the resulting fixed package is previewed by selected developers
- the fixed package is shipped

[=NOTE]
.ul compact
- It is project policy to avoid fixes to publicly released packages, as
  always the complete *WarpIN* package is to be shipped. So normally
  the fix procedure can only be used while a release is not yet
  published to the public, otherwise it is like releasing a new version.

