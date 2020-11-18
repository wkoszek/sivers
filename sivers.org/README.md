sivers.org
==========

My [sivers.org](http://sivers.org/) site.

A 2013 rewrite, moving content from database to static files.

## How it works:

### Writing:

I write my stuff in plain text files in one of the content/{blog,books,pages,presentations,tweets}/ directories.

* The date is in the filename.
* The URI for final publishing is in the filename.
* The title is in the first line of the file.
* Any other metadata needed is at the top.
* The rest is the content body, often written in HTML.

### Templates:

Plain erb Ruby templates are in templates/

Shared header and footer for the whole site.

Much of it is just hard-coded HTML.  (After all these years, I think it's easier to maintain than systems that hide the HTML.)

### Merging:

A Ruby script goes through all the content directories and reads the files.

* It starts an array for the collection of content in each subdirectory.
* It knows how to get the metadata needed for the different types and templates.
* It parses each file, gets the metadata, merges it into the template, and writes it to disk.
* Afterwards, it uses the collection array to merge with the index template, and writes that to disk.
* Finally, it uses all the collections to write the home page, which shows the newest additions of various types.

### Styling:

Styling made by @extend'ing in the SCSS file, instead of adding HTML attributes.

### Serving:

Nginx serves the final static site from the site/ directory.

Nginx passes certain paths by proxy to the dynamic Sinatra server, for dynamic pages, in [50web](http://code.sivers.org/50web/)

### Downloads:

Some files need to be in sivers.org/file/ for download.  A whitelist of these filenames is in a file called files.

### Redirects:

Old posts, instead of 404, are often sent somewhere else.  These are in a file called redirs.

# JUST THINKING:

## Translation

Languages: en, fr, es, pt, zh, ja

What gets translated:

* content/blog
* content/pages (including home)
* template/header.erb will need variable for masthead

Maybe I just keep an array of URIs to be translated?  Like don't translate tech articles and out-dated announcements.  Except I want to translate almost-everything, so maybe it would be a "skip-translation" list.

Would be nice to have one translator per language.  Someone that already likes my writing.

## Tags

I could add a new meta-header to every blog file, but instead it seems easier to maintain if I just keep a list of URIs in a text file with 1 uri per line:

* tags/tech
* tags/biz
* tags/music
* tags/life

Then for posts like company announcements that I'm happy to have fade into history, no tags at all.

Rakefile will keep hash map of {uri => title}, then at the end of site-generation, create index pages at site/tech site/biz.  Could do RSS for each.

