CREATE TABLE concepts (
	id integer primary key,
	created_at date not null default CURRENT_DATE,
	title varchar(127) not null unique CONSTRAINT title_not_empty CHECK (length(title) > 0),
	concept text not null unique CONSTRAINT concept_not_empty CHECK (length(concept) > 0)
);

CREATE TABLE urls (
	id integer primary key,
	url text not null unique CONSTRAINT url_not_empty CHECK (length(url) > 0),
	notes text
);

CREATE TABLE tags (
	id integer primary key,
	tag varchar(32) not null unique CONSTRAINT emptytag CHECK (length(tag) > 0)
);

CREATE TABLE concepts_urls (
	concept_id integer not null references concepts(id) on delete cascade,
	url_id integer not null references urls(id) on delete cascade,
	primary key (concept_id, url_id)
);

CREATE TABLE concepts_tags (
	concept_id integer not null references concepts(id) on delete cascade,
	tag_id integer not null references tags(id) on delete cascade,
	primary key (concept_id, tag_id)
);

CREATE TABLE pairings (
	id integer primary key,
	created_at date not null default CURRENT_DATE,
	concept1_id integer not null references concepts(id) on delete cascade,
	concept2_id integer not null references concepts(id) on delete cascade,
	thoughts text,
	CHECK(concept1_id != concept2_id),
	UNIQUE(concept1_id, concept2_id)
);

