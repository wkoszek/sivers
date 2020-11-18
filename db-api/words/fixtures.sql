--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = words, pg_catalog;

--
-- Data for Name: articles; Type: TABLE DATA; Schema: words; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

INSERT INTO translators(person_id, lang) VALUES(7, 'zh');


ALTER TABLE articles DISABLE TRIGGER ALL;

INSERT INTO articles (id, filename, raw, template) VALUES (1, 'finished', '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>', '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>');
INSERT INTO articles (id, filename, raw, template) VALUES (2, 'unfinished', '<h1>hello</h1><p>not done yet</p>', '<h1>{bbbbbbbb}</h1><p>{bbbbbbbc}</p>');


ALTER TABLE articles ENABLE TRIGGER ALL;

--
-- Name: articles_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('articles_id_seq', 2, true);


--
-- Data for Name: sentences; Type: TABLE DATA; Schema: words; Owner: d50b
--

INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('aaaaaaaa', 1, 1, '{}', 'headline here');
INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('aaaaaaab', 1, 2, '{<strong>,</strong>}', 'Some <bold words>.');
INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('aaaaaaac', 1, 3, '{"<a href=\"/\">",<em>,</em>,</a>}', 'Now <linked and <italic> words>.');
INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('aaaaaaad', 1, 4, '{"<a href=\"/about\">",</a>,"<a href=\"/\">",</a>}', 'See <about> <this>?');
INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('bbbbbbbb', 2, 1, '{}', 'hello');
INSERT INTO sentences (code, article_id, sortid, replacements, sentence) VALUES ('bbbbbbbc', 2, 2, '{}', 'not done yet');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaaa', 'es', 'título aquí');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaaa', 'fr', 'titre ici');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaaa', 'pt', 'headline aqui');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaaa', 'zh', '这里头条');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaab', 'es', 'algunas <palabras en negrita>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaab', 'fr', 'quelques <mots en gras>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaab', 'pt', 'algumas <palavras em negrito>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaab', 'zh', '一些大<胆的话>');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaac', 'es', 'Ahora <ligado y las <palabras en cursiva>>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaac', 'fr', 'maintenant <liés et mots <italiques>>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaac', 'pt', 'agora <ligados e as palavras em <itálico>>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaac', 'zh', '在<联和<斜体>字>');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaad', 'es', 'conocer <de> <este>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaad', 'fr', 'voir <à ce> <sujet>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaad', 'pt', 'ver <sobre> <este>');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('aaaaaaad', 'zh', '<到><这个>');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('bbbbbbbb', 'es', 'hola');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('bbbbbbbb', 'fr', 'bonjour');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('bbbbbbbb', 'pt', 'olá');
INSERT INTO translations(sentence_code, lang, translation) VALUES ('bbbbbbbb', 'zh', '你好');

INSERT INTO translations(sentence_code, lang, translation) VALUES ('bbbbbbbc', 'zh',  '还没做完');
INSERT INTO translations(sentence_code, lang) VALUES ('bbbbbbbc', 'es');
INSERT INTO translations(sentence_code, lang) VALUES ('bbbbbbbc', 'fr');
INSERT INTO translations(sentence_code, lang) VALUES ('bbbbbbbc', 'pt');
