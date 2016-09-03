##    Copyright © 2016 Rowan Thorpe, initially based entirely on a "taskdb" demo-app
##    posted by Joe Bognor at http://picolisp.com/wiki/?taskdb on 24 August 2016, and
##    intended to develop extensively from there.
##
##    This file is part of Picotask.
##
##    Picotask is free software: you can redistribute it and/or modify
##    it under the terms of the GNU Affero General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    Picotask is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU Affero General Public License for more details.
##
##    You should have received a copy of the GNU Affero General Public License
##    along with Picotask.  If not, see <http://www.gnu.org/licenses/>.

(load "@lib/misc.l" "@lib/btree.l" "@lib/db.l") # "@lib/pilog.l" "@lib/debug.l"

## INTERNAL FUNCTIONS

(de task-error (Error)
    (prinl (pack "ERROR: " Error))
    NIL )

(de task-known-status (Status)
   (case Status
      # "NEW" status can never be manually set, only by creating the task
      (("OPEN" "DONE" "ACTION" "WAITFOR" "DELEGATED") T)
      (T (task-error "Status is not one of OPEN, DONE, ACTION, WAITFOR, DELEGATED")) ) )

(de task-val-or-tasknum (Item)
   (if (= (type Item) '(+Task))
      (with Item (: number))
      Item ) )

## CORE PUBLIC FUNCTIONS

# Adds a task. Uses default priority of 1000 if not specified
# Usage: (task-add "call home")
(de task-add (Taskname Priority Due Parent Children Blocks Blockedby Tags Comment)
   (when Taskname
      (new! '(+Task)
         'number (genKey 'number '+Task)
         'name Taskname
         'status "NEW"
         'priority (or Priority 1000)
         'due Due
         'parent Parent
         'children Children
         'blocks Blocks
         'blockedby Blockedby
         'tags Tags
         'comment Comment ) ) )

# Deletes a task
# Usage: (task-delete 1)
(de task-delete (Number)
   (lose!> (db 'number '+Task Number)) )

# Edits a task (first arg =T to add/set, =NIL to remove/clear)
# Usage: (task-edit T 2 'status "WAITFOR"), (task-edit NIL 1 'blocks 3), etc
(de task-edit (Set Number . @)
   (if Set
      (case (arg 1)
         ("status" (when (task-known-status (arg 2)) (put!> (db 'number '+Task Number) (arg 1) (arg 2))))
         (("name" "priority" "comment") (put!> (db 'number '+Task Number) (arg 1) (arg 2)))
         ("tags" (put!> (db 'number '+Task Number) (arg 1) (if (lst? (arg 2)) (append (get (db 'number '+Task Number) (arg 1)) (arg 2)) (arg 2))))
         ("due" (let (Date ($dat (arg 2) *DateSep)) (if (= NIL Date) (task-error "Unrecognised due-date format") (put!> (db 'number '+Task Number) (arg 1) Date))))
         ("parent" (put!> (db 'number '+Task Number) (arg 1) (db 'number '+Task (arg 2))))
         (("children" "blocks" "blockedby") (put!> (db 'number '+Task Number) (arg 1) (if (lst? (arg 2)) (append (get (db 'number '+Task Number) (arg 1)) (mapcar '((Y) (db 'number '+Task Y)) (arg 2))) (db 'number '+Task (arg 2)))))
         (T (prinl "Operation not allowed") NIL) )
      (case (arg 1)
         ("tags" (if (lst? (arg 2)) (mapcar '((X) (del!> (db 'number '+Task Number) (arg 1) X)) (arg 2)) (del!> (db 'number '+Task Number) (arg 1) X)))
         (("comment" "due" "parent") (put!> (db 'number '+Task Number) (arg 1) NIL))
         (("children" "blocks" "blockedby") (if (lst? (arg 2)) (mapcar '((X) (del!> (db 'number '+Task Number) (arg 1) (db 'number '+Task X))) (arg 2)) (del!> (db 'number '+Task Number) (arg 1) (arg 2))))
         (T (prinl "Operation not allowed") NIL) ) ) )

# Fetch properties of a task from an external symbol
# Usage: (task-fetch '{4})
(de task-fetch (This)
   (list
      'number (: number)
      'name (: name)
      'status (: status)
      'priority (: priority)
      'due (: due)
      'parent (: parent)
      'children (: children)
      'blocks (: blocks)
      'blockedby (: blockedby)
      'tags (: tags)
      'comment (: comment) ) )

## Returns a list of all tasks matching criteria
## Usage: (task-all), (task-all 'priority 1000 2000), (task-all 'tags "mytag"), (task-all 'due "2016-08-16")...
(de task-all @
   (case (arg 1)
      (NIL (collect 'number '+Task))
      ("priority" (collect (arg 1) '+Task
            (arg 2)
            (or (arg 3) (arg 2)) ))
      ("due" (collect (arg 1) '+Task
            ($dat (arg 2) *DateSep)
            ($dat (or (arg 3) (arg 2)) *DateSep) ))
      (("name" "status" "parent" "children" "blocks" "blockedby" "tags" "comment") (collect (arg 1) '+Task (arg 2)))
      (T (prinl "Operation not allowed") NIL) ) )

## Shows all tasks matching criteria, without expanding linked DB IDs
## Usage: (task-show-raw), (task-show-raw 'priority 1000 2000), (task-show-raw 'tags "mytag"),
##        (task-show-raw 'due "2016-08-16")...
(de task-show-raw @
   (mapcar task-fetch (pass task-all)) )

## Shows all tasks matching criteria, expanding linked DB IDs
## Usage: (task-show), (task-show 'priority 1000 2000), (task-show 'tags "mytag"),
##        (task-show 'due "2016-08-16")...
(de task-show @
   (mapcar '((Task)
      (mapcar '((TaskEntry)
         (if (and (not (= NIL TaskEntry)) (lst? TaskEntry))
            (mapcar task-val-or-tasknum TaskEntry)
            (task-val-or-tasknum TaskEntry) )) Task))
               (pass task-show-raw) ) )

## Prints all tasks matching criteria, one per line, without expanding linked DB IDs
## Usage: (task-print-raw), (task-print-raw 'priority 1000 2000), (task-print-raw 'tags "mytag"),
##        (task-print-raw 'due "2016-08-16")...
(de task-print-raw @
    (mapcar println (pass task-show-raw))
    NIL )

## Prints all tasks matching criteria, one per line, expanding linked DB IDs
## Usage: (task-print), (task-print 'priority 1000 2000), (task-print 'tags "mytag"),
##        (task-print 'due "2016-08-16")...
(de task-print @
   (mapcar println (pass task-show))
   NIL )
    
## Help output
## Usage: (task-help)
(de task-help ()
   (prinl "(task-add Taskname, [Priority, Due, Parent, Children, Blocks, Blockedby, Tags, Comment])")
   (prinl "(task-delete Tasknumber)")
   (prinl "(task-edit T/NIL=add/remove, Tasknumber, [FieldName, ...])")
   (prinl "(task-fetch TaskExternalSymbol)")
   (prinl "(task-all [FieldName, arg1/start, [arg2/end]])")
   (prinl "(task-show-raw [FieldName, arg1/start, [arg2/end]])")
   (prinl "(task-show [FieldName, arg1/start, [arg2/end]])")
   (prinl "(task-print-raw [FieldName, arg1/start, [arg2/end]])")
   (prinl "(task-print [FieldName, arg1/start, [arg2/end]])")
   (prinl "(task-status Number Status)")
   (prinl "(task-done Number)")
   (prinl "(task-open Number)")
   (prinl "(task-rename Number Name)")
   (prinl "(task-priority Number Priority)")
   (prinl "(task-tag Number Tag)")
   (prinl "(task-untag Number Tag)")
   (prinl "(task-comment Number Comment)")
   (prinl "(task-uncomment Number)")
   (prinl "(task-due Number Due)")
   (prinl "(task-undue Number)")
   (prinl "(task-parent Number PNumber)")
   (prinl "(task-unparent Number)")
   (prinl "(task-child Number CNumber)")
   (prinl "(task-unchild Number CNumber)")
   (prinl "(task-block Number BNumber)")
   (prinl "(task-unblock Number BNumber)")
   (prinl "(task-help)")
   NIL )

## CORE PUBLIC CONVENIENCE FUNCTIONS

(de task-status (Number Status)
   (task-edit T Number 'status Status) )

(de task-done (Number)
   (task-status Number "DONE") )

(de task-open (Number)
   (task-status Number "OPEN") )

(de task-rename (Number Name)
   (task-edit T Number 'name Name) )

(de task-priority (Number Priority)
   (task-edit T Number 'priority Priority) )

(de task-tag (Number Tag)
   (task-edit T Number 'tags Tag) )

(de task-untag (Number Tag)
   (task-edit NIL Number 'tags Tag) )

(de task-comment (Number Comment)
   (task-edit T Number 'comment Comment) )

(de task-uncomment (Number)
   (task-edit NIL Number 'comment) )

(de task-due (Number Due)
   (task-edit T Number 'due Due) )

(de task-undue (Number)
   (task-edit NIL Number 'due) )

(de task-parent (Number PNumber)
   (task-edit T Number 'parent PNumber) )

(de task-unparent (Number)
   (task-edit NIL Number 'parent) )

(de task-child (Number CNumber)
   (task-edit T Number 'children CNumber) )

(de task-unchild (Number CNumber)
   (task-edit NIL Number 'children CNumber) )

(de task-block (Number BNumber)
   (task-edit T Number 'blocks BNumber) )

(de task-unblock (Number BNumber)
   (task-edit NIL Number 'blocks BNumber) )

## FRONTEND FUNCTIONS

(de connect-db ()
   (pool *TaskDBFile) ) ## initial database (consider block size)

(de main ()
   (connect-db) )
   #(when [run as commandline tool]
   #   (...parse argv, execute functions...)
   #   (bye) )

#(de webserve ()
#   (connect-db)
#   (server 8081 "!work") )
