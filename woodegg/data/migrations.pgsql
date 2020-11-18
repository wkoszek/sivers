-- 2014-01-10
ALTER TABLE woodegg.books ADD COLUMN apple integer;

-- 2014-01-03
ALTER TABLE woodegg.books ADD COLUMN pages integer;

-- 2013-12-05
INSERT INTO woodegg.topics (id, topic) VALUES (0, 'Now');
UPDATE woodegg.subtopics SET topic_id=0 WHERE id IN (3, 4);
INSERT INTO woodegg.subtopics (id, topic_id, subtopic) VALUES (0, 0, 'Introduction');
INSERT INTO woodegg.template_questions (id, subtopic_id, question) VALUES (0, 0, 'Understanding {COUNTRY}');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'ID', 'Understanding Indonesia');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'JP', 'Understanding Japan');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'KR', 'Understanding Korea');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'MM', 'Understanding Myanmar');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'SG', 'Understanding Singapore');
INSERT INTO woodegg.questions (template_question_id, country, question) VALUES (0, 'TW', 'Understanding Taiwan');
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3315, 4, NOW(), NOW(), true, 21);
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3316, 4, NOW(), NOW(), true, 22);
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3317, 4, NOW(), NOW(), true, 23);
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3318, 4, NOW(), NOW(), true, 26);
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3319, 4, NOW(), NOW(), true, 28);
INSERT INTO woodegg.essays (question_id, writer_id, started_at, finished_at, payable, book_id) VALUES (3320, 4, NOW(), NOW(), true, 30);

-- 2013-11-30
ALTER TABLE woodegg.researchers ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);
ALTER TABLE woodegg.writers ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);
ALTER TABLE woodegg.editors ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);
ALTER TABLE woodegg.customers ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);
ALTER TABLE woodegg.test_essays ADD FOREIGN KEY (person_id) REFERENCES peeps.people(id);

-- 2013-11-20
ALTER TABLE books ADD COLUMN credits text;

-- 2013-11-01
ALTER TABLE editors ADD COLUMN bio text;

-- 2013-10-17
ALTER TABLE test_essays ALTER COLUMN question_id DROP NOT NULL;
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'HK', (SELECT question_id FROM essays WHERE id=3961), (SELECT content FROM essays WHERE id=3961));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'JP', (SELECT question_id FROM essays WHERE id=3559), (SELECT content FROM essays WHERE id=3559));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'KR', (SELECT question_id FROM essays WHERE id=3833), (SELECT content FROM essays WHERE id=3833));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'MY', (SELECT question_id FROM essays WHERE id=3771), (SELECT content FROM essays WHERE id=3771));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'MN', (SELECT question_id FROM essays WHERE id=3920), (SELECT content FROM essays WHERE id=3920));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'PH', (SELECT question_id FROM essays WHERE id=4018), (SELECT content FROM essays WHERE id=4018));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'SG', (SELECT question_id FROM essays WHERE id=3549), (SELECT content FROM essays WHERE id=3549));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'LK', (SELECT question_id FROM essays WHERE id=3761), (SELECT content FROM essays WHERE id=3761));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'TW', (SELECT question_id FROM essays WHERE id=3462), (SELECT content FROM essays WHERE id=3462));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'VN', (SELECT question_id FROM essays WHERE id=3795), (SELECT content FROM essays WHERE id=3795));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'IN', (SELECT question_id FROM essays WHERE id=697), (SELECT content FROM essays WHERE id=697));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'ID', (SELECT question_id FROM essays WHERE id=874), (SELECT content FROM essays WHERE id=874));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'TH', (SELECT question_id FROM essays WHERE id=3917), (SELECT content FROM essays WHERE id=3917));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'KH', (SELECT question_id FROM essays WHERE id=3572), (SELECT content FROM essays WHERE id=3572));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'CN', (SELECT question_id FROM essays WHERE id=3954), (SELECT content FROM essays WHERE id=3954));
INSERT INTO test_essays (person_id, started_at, finished_at, country, question_id, content) VALUES (1, NOW(), NOW(), 'MM', 1171, (SELECT answer FROM answers WHERE id=11505));

-- 2013-09-26
CREATE INDEX esbi ON essays(book_id);

-- 2013-09-24
ALTER TABLE writers ADD COLUMN active boolean not null default TRUE;
UPDATE writers SET active=FALSE WHERE id <= 5;

-- 2013-09-08
ALTER TABLE uploads ADD COLUMN status varchar(4);

-- 2013-09-02
CREATE TABLE test_essays (
	id serial PRIMARY KEY,
	person_id integer not null,
	country char(2) not null,
	question_id integer not null REFERENCES questions(id),
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	content text,
	notes text
);

-- 2013-08-17
ALTER TABLE researchers ADD COLUMN active boolean not null default TRUE;
UPDATE researchers SET active=FALSE WHERE id < 55;
UPDATE researchers SET active=FALSE WHERE id IN (80, 87);
DELETE FROM books_researchers WHERE researcher_id IN (80, 87);

-- 2013-08-10
ALTER TABLE uploads ADD COLUMN duration varchar(7);

-- 2013-08-08
ALTER TABLE uploads ADD COLUMN uploaded char(1) NOT NULL DEFAULT 'n';

-- 2013-08-07
CREATE TABLE uploads (
	id serial PRIMARY KEY,
	created_at date NOT NULL DEFAULT CURRENT_DATE,
	researcher_id integer not null REFERENCES researchers(id),
	their_filename text not null,
	our_filename text not null,
	mime_type varchar(32),
	bytes integer,
	notes text,
	transcription text
);

-- 2013-07-08
DROP INDEX esca;
ALTER TABLE essays RENAME COLUMN cleaned_at TO edited_at;
CREATE INDEX esea ON essays(edited_at);
ALTER TABLE essays DROP COLUMN cleaned_by;
ALTER TABLE essays ADD COLUMN editor_id integer;
UPDATE essays SET editor_id=1;
ALTER TABLE essays ADD FOREIGN KEY (editor_id) REFERENCES editors(id);

-- 2013-07-07
ALTER TABLE essays RENAME COLUMN comment TO edited;
UPDATE essays SET edited=content;

-- 2013-06-26
CREATE TABLE editors (
	id serial primary key,
	person_id integer not null UNIQUE
);
INSERT INTO editors (person_id) VALUES (1);
CREATE TABLE books_editors (
	book_id integer not null REFERENCES books(id),
	editor_id integer not null REFERENCES editors(id),
	PRIMARY KEY (book_id, editor_id)
);
INSERT INTO books_editors (book_id, editor_id) VALUES (1, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (2, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (3, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (4, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (5, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (6, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (7, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (8, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (9, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (10, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (11, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (12, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (13, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (14, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (15, 1);
INSERT INTO books_editors (book_id, editor_id) VALUES (16, 1);


-- 2013-06-25
BEGIN;
CREATE TABLE writers (
	id serial primary key,
	person_id integer not null UNIQUE,
	bio text
);
INSERT INTO writers (SELECT * FROM editors);
CREATE TABLE books_writers (
	book_id integer not null REFERENCES books(id),
	writer_id integer not null REFERENCES writers(id),
	PRIMARY KEY (book_id, writer_id)
);
INSERT INTO books_writers (SELECT book_id, editor_id AS writer_id FROM books_editors);

ALTER TABLE essays DROP CONSTRAINT essays_editor_id_fkey;
DROP INDEX espi;
ALTER TABLE essays RENAME COLUMN editor_id TO writer_id;
ALTER TABLE essays ADD CONSTRAINT essays_writer_id_fkey FOREIGN KEY (writer_id) REFERENCES writers(id);
CREATE INDEX eswi ON essays(writer_id);

DROP TABLE books_editors;
DROP TABLE editors;
COMMIT;


-- 2013-06-21
CREATE TABLE tags (
	id serial primary key,
	name varchar(16) UNIQUE
);
INSERT INTO tags(name) VALUES ('Cambodia');
INSERT INTO tags(name) VALUES ('China');
INSERT INTO tags(name) VALUES ('Hong Kong');
INSERT INTO tags(name) VALUES ('India');
INSERT INTO tags(name) VALUES ('Indonesia');
INSERT INTO tags(name) VALUES ('Japan');
INSERT INTO tags(name) VALUES ('Korea');
INSERT INTO tags(name) VALUES ('Malaysia');
INSERT INTO tags(name) VALUES ('Mongolia');
INSERT INTO tags(name) VALUES ('Myanmar');
INSERT INTO tags(name) VALUES ('Philippines');
INSERT INTO tags(name) VALUES ('Singapore');
INSERT INTO tags(name) VALUES ('Sri Lanka');
INSERT INTO tags(name) VALUES ('Taiwan');
INSERT INTO tags(name) VALUES ('Thailand');
INSERT INTO tags(name) VALUES ('Vietnam');

CREATE TABLE tidbits (
	id serial primary key,
	created_at date,
	created_by varchar(16),
	headline varchar(127),
	url text,
	intro text,
	content text
);

CREATE TABLE tags_tidbits (
	tag_id integer not null REFERENCES tags(id) ON DELETE CASCADE,
	tidbit_id integer not null REFERENCES tidbits(id) ON DELETE CASCADE,
	primary key (tag_id, tidbit_id)
);

CREATE TABLE questions_tidbits (
	question_id integer not null REFERENCES questions(id) ON DELETE CASCADE,
	tidbit_id integer not null REFERENCES tidbits(id) ON DELETE CASCADE,
	primary key (question_id, tidbit_id)
);


-- 2013-06-18
UPDATE userstats SET statvalue='editor' WHERE statvalue IN ('2014editor', 'editing');
UPDATE userstats SET statvalue='writer' WHERE statvalue IN ('2014writer', 'writer?');
UPDATE userstats SET statvalue='researcher' WHERE statvalue IN ('2014researcher', 'journalist');
UPDATE userstats SET statvalue='connector' WHERE statvalue IN ('conatacts', 'connect', 'contact' ,'contacts', 'liason', 'liaison');
UPDATE userstats SET statvalue='accountant' WHERE statvalue = 'cpa';
UPDATE userstats SET statvalue='interview' WHERE statvalue IN ('Interview', 'interviewee', 'inteview');
UPDATE userstats SET statvalue='design' WHERE statvalue = 'artwork';
UPDATE userstats SET statvalue='interest' WHERE statvalue = 'intererest';


-- 2013-06-05
ALTER TABLE books ADD COLUMN code char(6) UNIQUE;
UPDATE books SET code = CONCAT('we13' || LOWER(country));   

-- 2013-05-30
CREATE TABLE customers (
	id serial primary key,
	person_id integer not null UNIQUE
);
CREATE TABLE books_customers (
	book_id integer not null references books(id),
	customer_id integer not null references customers(id),
	primary key (book_id, customer_id)
);

-- 2013-05-29
ALTER TABLE books ADD COLUMN asin char(10);
ALTER TABLE books ADD COLUMN leanpub varchar(30);

-- 2013-05-21
ALTER TABLE books ADD COLUMN salescopy text;

-- 2013-04-26
ALTER TABLE answers RENAME COLUMN person_id TO researcher_id;
UPDATE answers SET researcher_id=1 WHERE researcher_id=327768;
UPDATE answers SET researcher_id=2 WHERE researcher_id=333347;
UPDATE answers SET researcher_id=3 WHERE researcher_id=333392;
UPDATE answers SET researcher_id=4 WHERE researcher_id=324695;
UPDATE answers SET researcher_id=5 WHERE researcher_id=327760;
UPDATE answers SET researcher_id=6 WHERE researcher_id=333466;
UPDATE answers SET researcher_id=7 WHERE researcher_id=313008;
UPDATE answers SET researcher_id=8 WHERE researcher_id=327755;
UPDATE answers SET researcher_id=9 WHERE researcher_id=310915;
UPDATE answers SET researcher_id=10 WHERE researcher_id=327765;
UPDATE answers SET researcher_id=11 WHERE researcher_id=327787;
UPDATE answers SET researcher_id=12 WHERE researcher_id=327763;
UPDATE answers SET researcher_id=13 WHERE researcher_id=327786;
UPDATE answers SET researcher_id=14 WHERE researcher_id=333622;
UPDATE answers SET researcher_id=15 WHERE researcher_id=306439;
UPDATE answers SET researcher_id=16 WHERE researcher_id=333342;
UPDATE answers SET researcher_id=17 WHERE researcher_id=333449;
UPDATE answers SET researcher_id=18 WHERE researcher_id=327757;
UPDATE answers SET researcher_id=19 WHERE researcher_id=327758;
UPDATE answers SET researcher_id=20 WHERE researcher_id=327759;
UPDATE answers SET researcher_id=21 WHERE researcher_id=327762;
UPDATE answers SET researcher_id=22 WHERE researcher_id=326583;
UPDATE answers SET researcher_id=23 WHERE researcher_id=327767;
UPDATE answers SET researcher_id=24 WHERE researcher_id=333884;
UPDATE answers SET researcher_id=25 WHERE researcher_id=333995;
UPDATE answers SET researcher_id=26 WHERE researcher_id=312089;
UPDATE answers SET researcher_id=27 WHERE researcher_id=335843;
UPDATE answers SET researcher_id=28 WHERE researcher_id=311591;
UPDATE answers SET researcher_id=29 WHERE researcher_id=324731;
UPDATE answers SET researcher_id=30 WHERE researcher_id=327752;
UPDATE answers SET researcher_id=31 WHERE researcher_id=327840;
UPDATE answers SET researcher_id=32 WHERE researcher_id=305369;
UPDATE answers SET researcher_id=33 WHERE researcher_id=323938;
UPDATE answers SET researcher_id=34 WHERE researcher_id=327761;
UPDATE answers SET researcher_id=35 WHERE researcher_id=327754;
UPDATE answers SET researcher_id=36 WHERE researcher_id=327764;
UPDATE answers SET researcher_id=37 WHERE researcher_id=327775;
UPDATE answers SET researcher_id=38 WHERE researcher_id=320686;
UPDATE answers SET researcher_id=39 WHERE researcher_id=322353;
UPDATE answers SET researcher_id=40 WHERE researcher_id=327766;
UPDATE answers SET researcher_id=41 WHERE researcher_id=327848;
UPDATE answers SET researcher_id=42 WHERE researcher_id=327856;
UPDATE answers SET researcher_id=43 WHERE researcher_id=314333;
UPDATE answers SET researcher_id=44 WHERE researcher_id=327748;
UPDATE answers SET researcher_id=45 WHERE researcher_id=327753;
UPDATE answers SET researcher_id=46 WHERE researcher_id=59196;
UPDATE answers SET researcher_id=47 WHERE researcher_id=327776;
UPDATE answers SET researcher_id=48 WHERE researcher_id=333402;
UPDATE answers SET researcher_id=49 WHERE researcher_id=333445;
UPDATE answers SET researcher_id=50 WHERE researcher_id=334038;
UPDATE answers SET researcher_id=51 WHERE researcher_id=334039;
ALTER TABLE answers ADD FOREIGN KEY (researcher_id) REFERENCES researchers(id);

INSERT INTO editors (person_id) VALUES (1);      -- 4
INSERT INTO editors (person_id) VALUES (338873); -- 5
ALTER TABLE essays RENAME COLUMN person_id TO editor_id;
UPDATE essays SET editor_id=4 WHERE editor_id=1;
UPDATE essays SET editor_id=5 WHERE editor_id=338873;
UPDATE essays SET editor_id=1 WHERE editor_id=331600;
UPDATE essays SET editor_id=2 WHERE editor_id=331709;
UPDATE essays SET editor_id=3 WHERE editor_id=338825;
ALTER TABLE essays ADD FOREIGN KEY (editor_id) REFERENCES editors(id);

