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

(load "@lib/misc.l" "@lib/btree.l") # "@lib/db.l" "@lib/pilog.l" "@lib/debug.l"

#### INTERNAL FUNCTIONS

(symbols 'picotask 'pico)

(de error (Error)
    (prinl (pack "ERROR: " Error))
    NIL )

(de known-status (Status)
   (case Status
      # "NEW" status can never be manually set, only by creating the task
      (("OPEN" "DONE" "ACTION" "WAITFOR" "DELEGATED") T)
      (T (error "Status is not one of OPEN, DONE, ACTION, WAITFOR, DELEGATED")) ) )

(de val-or-tasknum (Item)
   (if (= (type Item) '(+Task))
      (with Item (: number))
      Item ) )

(de get-or-set (Number Field Val)
   (if Val
      (modify T Number Field Val)
      (get (db 'number '+Task Number) Field) ) )

#### CORE PUBLIC FUNCTIONS

# Adds a task. Uses default priority of 1000 if not specified
# Usage: (add "call home")
(de add (Taskname Priority Due Parent Children Blocks Blockedby Tags Comment)
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

# Destroys a task
# Usage: (destroy 1)
(de destroy (Number)
   (lose!> (db 'number '+Task Number)) )

# Modifies a task (first arg =T to add/set, =NIL to remove/clear)
# Usage: (modify T 2 'status "WAITFOR"), (modify NIL 1 'blocks 3), etc
(de modify (Set Number . @)
   (if Set
      (case (arg 1)
         ("status" (when (known-status (arg 2)) (put!> (db 'number '+Task Number) (arg 1) (arg 2))))
         (("name" "priority" "comment") (put!> (db 'number '+Task Number) (arg 1) (arg 2)))
         ("tags" (put!> (db 'number '+Task Number) (arg 1) (if (lst? (arg 2)) (append (get (db 'number '+Task Number) (arg 1)) (arg 2)) (arg 2))))
         ("due" (let (Date ($dat (arg 2) *DateSep)) (if (= NIL Date) (error "Unrecognised due-date format") (put!> (db 'number '+Task Number) (arg 1) Date))))
         ("parent" (put!> (db 'number '+Task Number) (arg 1) (db 'number '+Task (arg 2))))
         (("children" "blocks" "blockedby") (put!> (db 'number '+Task Number) (arg 1) (if (lst? (arg 2)) (append (get (db 'number '+Task Number) (arg 1)) (mapcar '((Y) (db 'number '+Task Y)) (arg 2))) (db 'number '+Task (arg 2)))))
         (T (prinl "Operation not allowed") NIL) )
      (case (arg 1)
         ("tags" (if (lst? (arg 2)) (mapcar '((X) (del!> (db 'number '+Task Number) (arg 1) X)) (arg 2)) (del!> (db 'number '+Task Number) (arg 1) X)))
         (("comment" "due" "parent") (put!> (db 'number '+Task Number) (arg 1) NIL))
         (("children" "blocks" "blockedby") (if (lst? (arg 2)) (mapcar '((X) (del!> (db 'number '+Task Number) (arg 1) (db 'number '+Task X))) (arg 2)) (del!> (db 'number '+Task Number) (arg 1) (arg 2))))
         (T (prinl "Operation not allowed") NIL) ) ) )

# Retrieve properties of a task from an external symbol
# Usage: (retrieve '{4})
(de retrieve (This)
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

## Returns an index of all tasks matching criteria
## Usage: (ind), (ind 'priority 1000 2000), (ind 'tags "mytag"), (ind 'due "2016-08-16")...
(de ind @
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

## Returns all tasks matching criteria, without expanding linked DB IDs
## Usage: (return-raw), (return-raw 'priority 1000 2000), (return-raw 'tags "mytag"),
##        (return-raw 'due "2016-08-16")...
(de return-raw @
   (mapcar retrieve (pass ind)) )

## Returns all tasks matching criteria, expanding linked DB IDs
## Usage: (return), (return 'priority 1000 2000), (return 'tags "mytag"),
##        (return 'due "2016-08-16")...
(de return @
   (mapcar '((Task)
      (mapcar '((TaskEntry)
         (if (and (not (= NIL TaskEntry)) (lst? TaskEntry))
            (mapcar val-or-tasknum TaskEntry)
            (val-or-tasknum TaskEntry) )) Task))
               (pass return-raw) ) )

## Displays all tasks matching criteria, one per line, without expanding linked DB IDs
## Usage: (display-raw), (display-raw 'priority 1000 2000), (display-raw 'tags "mytag"),
##        (display-raw 'due "2016-08-16")...
(de display-raw @
    (mapcar println (pass return-raw))
    NIL )

## Displays all tasks matching criteria, one per line, expanding linked DB IDs
## Usage: (display), (display 'priority 1000 2000), (display 'tags "mytag"),
##        (display 'due "2016-08-16")...
(de display @
   (mapcar println (pass return))
   NIL )

## License/Copyright output
## Usage: (license)
(de license ()
   (prinl "Picotask

Copyright © 2016 Rowan Thorpe, initially based entirely on a \"taskdb\" demo-app
posted by Joe Bognor at http://picolisp.com/wiki/?taskdb on 24 August 2016, and
intended to develop extensively from there.

Picotask is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Picotask is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with Picotask.  If not, see <http://www.gnu.org/licenses/>.")
   NIL )

## Source output (AGPL compliance)
## Usage: (source)
(de source ()
   (prinl "****** picotask executable")
   (prinl)
   (in "__EXECDIR__/picotask" (prinl (till NIL T)))
   (prinl "****** picotask config")
   (prinl)
   (in "__CONFDIR__/picotask.l" (prinl (till NIL T)))
   (prinl "****** libpicolisp.l")
   (prinl)
   (in "__LIBDIR__/libpicotask.l" (prinl (till NIL T)))
   NIL )

## Help output
## Usage: (help)
(de help ()
   (prinl "(add Taskname, [Priority, Due, Parent, Children, Blocks, Blockedby, Tags, Comment])")
   (prinl "(destroy Tasknumber)")
   (prinl "(modify T/NIL=add/remove, Tasknumber, [FieldName, ...])")
   (prinl "(retrieve TaskExternalSymbol)")
   (prinl "(ind [FieldName, arg1/start, [arg2/end]])")
   (prinl "(return-raw [FieldName, arg1/start, [arg2/end]])")
   (prinl "(return [FieldName, arg1/start, [arg2/end]])")
   (prinl "(display-raw [FieldName, arg1/start, [arg2/end]])")
   (prinl "(display [FieldName, arg1/start, [arg2/end]])")
   (prinl "(license)")
   (prinl "(source)")
   (prinl "(help)")
   (prinl "(status Number Status)")
   (prinl "(isdone Number)")
   (prinl "(isopen Number)")
   (prinl "(rename Number Name)")
   (prinl "(priority Number Priority)")
   (prinl "(tag Number Tag)")
   (prinl "(untag Number Tag)")
   (prinl "(comment Number Comment)")
   (prinl "(uncomment Number)")
   (prinl "(due Number Due)")
   (prinl "(undue Number)")
   (prinl "(parent Number PNumber)")
   (prinl "(unparent Number)")
   (prinl "(child Number CNumber)")
   (prinl "(unchild Number CNumber)")
   (prinl "(block Number BNumber)")
   (prinl "(unblock Number BNumber)")
   (prinl "(connectdb)")
   NIL )

#### PUBLIC WRAPPER FUNCTIONS

(de status (Number Status)
   (get-or-set Number 'status Status) )

(de setdone (Number)
   (status Number "DONE") )

(de setopen (Number)
   (status Number "OPEN") )

(de rename (Number Name)
   (get-or-set Number 'name Name) )

(de priority (Number Priority)
   (get-or-set Number 'priority Priority) )

(de tag (Number Tag)
   (get-or-set Number 'tags Tag) )

(de untag (Number Tag)
   (modify NIL Number 'tags Tag) )

(de comment (Number Comment)
   (get-or-set Number 'comment Comment) )

(de uncomment (Number)
   (modify NIL Number 'comment) )

(de due (Number Due)
   (get-or-set Number 'due Due) )

(de undue (Number)
   (modify NIL Number 'due) )

(de parent (Number PNumber)
   (get-or-set Number 'parent PNumber) )

(de unparent (Number)
   (modify NIL Number 'parent) )

(de child (Number CNumber)
   (get-or-set Number 'children CNumber) )

(de unchild (Number CNumber)
   (modify NIL Number 'children CNumber) )

(de block (Number BNumber)
   (get-or-set Number 'blocks BNumber) )

(de unblock (Number BNumber)
   (modify NIL Number 'blocks BNumber) )

#### FRONTEND FUNCTIONS

(de connectdb ()
   (pool *TaskDBFile) ) ## initial database (consider block size)

#(de webserve ()
#   (connectdb)
#   (server 8081 "!work") )
