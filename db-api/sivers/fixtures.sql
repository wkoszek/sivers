--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = sivers, pg_catalog;

--
-- Data for Name: comments; Type: TABLE DATA; Schema: sivers; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE comments DISABLE TRIGGER ALL;

INSERT INTO comments (id, uri, person_id, created_at, name, email, html) VALUES (1, 'trust', 2, '2014-02-01', 'Willy Wonka', 'willy@wonka.com', 'That is great.');
INSERT INTO comments (id, uri, person_id, created_at, name, email, html) VALUES (2, 'trust', 3, '2014-02-01', 'Veruca', 'veruca@salt.com', 'I''ve done better.');
INSERT INTO comments (id, uri, person_id, created_at, name, email, html) VALUES (3, 'done', 3, '2014-02-02', 'Veruca', 'veruca@salt.com', 'This is stupid!');
INSERT INTO comments (id, uri, person_id, created_at, name, email, html) VALUES (4, 'io', 5, '2014-04-28', 'Oompa', 'oompa@loompa.mm', 'spam1');
INSERT INTO comments (id, uri, person_id, created_at, name, email, html) VALUES (5, 'kl', 5, '2014-04-28', 'Loompa', 'oompa@loompa.mm', 'spam2');


ALTER TABLE comments ENABLE TRIGGER ALL;

--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: sivers; Owner: d50b
--

SELECT pg_catalog.setval('comments_id_seq', 5, true);


