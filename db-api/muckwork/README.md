# TODO:

## Worker:

* payments
* charges
* balance (dynamic)

## Client:

* payments
* charges
* sign up anew
* sign up using existing email + pass
* update all info
* locations & currencies
* mark new project as ready to be quoted
* create payment
* delete unstarted project
* client balance = dynamic, not fixed

# THOUGHTS:

Should client charge be based on project or task?  I originally thought project, but maybe seeing individual charges is more appealing?  And what if they choose to not finish a project?  (I'm assuming we'll mark a project as finished if they don't want to continue with it.)

What if a task needs to be started and stopped multiple times?  Probably need to remove timestamps from task and instead make 1-to-many timeworked table, tied to a task.

