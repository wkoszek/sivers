# TODO:

* web interface for untagged concepts
* new_pairing() function: instead of order by random(), do offset by random method?  Only thing is, I don't know how to calculate number of rows without re-doing the entire join query.

# Book notes?

If used for book notes, then lat.concepts kinda works except I don't need title or creation date.

CREATE TABLE books (
  id serial primary key,
  uri varchar(32) unique,
  title varchar(128)
);

CREATE TABLE quotes (
  id serial primary key,
  book_id integer not null references books(id),
  quote text,
  prev_quote integer references quotes(id),
  next_quote integer references quotes(id)
);

CREATE TABLE quotes_tags (
  quote_id integer not null references lat.quotes(id) on delete cascade,
  tag_id integer not null references lat.tags(id) on delete cascade,
  primary key (quote_id, tag_id)
);

## Generalized:

* kill concepts.created_at
* merge concepts.title into concept
* add book_id, left null if mine
* add next/prev

## Rank:

* add weight/ranking for concepts : tinyint

