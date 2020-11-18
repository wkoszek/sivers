# 50web

Websites in Sinatra accessing PostgreSQL API functions.

## why?

Before, these would have each been separate repositories, but I'm trying the approach of putting them all into one.  Why?

Because they'll all be running on internal localhost rackups, proxied by nginx.  I start them all in one go.  One workflow that doesn't abandon any site.

## how?

Assume each site has its own domain.  Each has its own nginx config.

## auth?

All use email + password, checked against peeps.people, then checking another table for that personId.  If found, set cookie.

* data = peeps.people only
* inbox = peeps.emailers
* kyc = peeps.emailers
* c.muck = muckwork.clients
* w.muck = muckwork.workers
* m.muck = muckwork.managers
* woodegg = woodegg.customers
* words = words.translators

# words site TODO:

* translator auth
* list of unfinished articles

