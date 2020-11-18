# musicthoughts.com

<http://musicthoughts.com/> has always been a sandbox playground for me, since I made it in 1999 using PHP.

Since then I’ve made it multi-lingual, converted it to Rails, then Ruby Sinatra, and now back to basics by making it static HTML.

Mostly copied directly from <https://github.com/50pop/50web>.

The only feature to disappear is “Add a Thought”, which unfortunately I wasn’t using anyway.  I’ve only added one or two new thoughts in years.  So this really is just a static site now.

For things that are the same for all sites, like robots.txt, CSS, and web fonts, they’re in a /shared/ directory above each site’s webroot, and Nginx config will send those requests there.

