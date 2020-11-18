SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS words CASCADE;
BEGIN;

CREATE SCHEMA words;
SET search_path = words;

CREATE TABLE words.translators (
	id smallserial primary key,
	person_id integer NOT NULL REFERENCES peeps.people(id),
	lang char(2) NOT NULL
);

-- "article" meaning ordered collection of sentences, with HTML markup
CREATE TABLE words.articles (
	id smallserial primary key,
	filename varchar(64) not null unique,
	raw text,
	template text
);

CREATE TABLE words.sentences (
	code char(8) primary key,
	article_id smallint REFERENCES words.articles(id),
	sortid smallint,
	replacements text[],
	sentence text
);

CREATE TABLE words.translations (
	id serial primary key,
	sentence_code char(8) NOT NULL REFERENCES words.sentences(code),
	lang char(2) not null,
	translation text,
	UNIQUE (sentence_code, lang)
);

COMMIT;
