--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = muckwork, pg_catalog;

--
-- Data for Name: clients; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE clients DISABLE TRIGGER ALL;

INSERT INTO clients (id, person_id, currency) VALUES (1, 2, 'USD');
INSERT INTO clients (id, person_id, currency) VALUES (2, 3, 'GBP');


ALTER TABLE clients ENABLE TRIGGER ALL;

--
-- Data for Name: projects; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE projects DISABLE TRIGGER ALL;

INSERT INTO projects (id, client_id, title, description, created_at, quoted_at, approved_at, started_at, finished_at, progress, quoted_money, quoted_ratetype, final_money) VALUES (1, 1, 'Finished project', 'by Wonka for Charlie', '2015-07-02 00:34:56+12', '2015-07-03 00:34:56+12', '2015-07-04 00:34:56+12', '2015-07-05 00:34:56+12', '2015-07-05 03:34:56+12', 'finished', ('USD', 50), 'time', ('USD', 45.36));
INSERT INTO projects (id, client_id, title, description, created_at, quoted_at, approved_at, started_at, finished_at, progress, quoted_money, quoted_ratetype, final_money) VALUES (2, 2, 'Started project', 'by Veruca for Oompa', '2015-07-06 00:34:56+12', '2015-07-07 00:34:56+12', '2015-07-08 00:34:56+12', '2015-07-09 00:34:56+12', NULL, 'started', ('GBP', 100), 'time', NULL);
INSERT INTO projects (id, client_id, title, description, created_at, quoted_at, approved_at, started_at, finished_at, progress, quoted_money, quoted_ratetype, final_money) VALUES (3, 1, 'Unstarted project', 'by Wonka', '2015-07-09 00:34:56+12', '2015-07-10 00:34:56+12', '2015-07-11 00:34:56+12', NULL, NULL, 'approved', ('USD', 100), 'time', NULL);
INSERT INTO projects (id, client_id, title, description, created_at, quoted_at, approved_at, started_at, finished_at, progress, quoted_money, quoted_ratetype, final_money) VALUES (4, 2, 'Unapproved project', 'by Veruca', '2015-07-12 00:34:56+12', '2015-07-13 00:34:56+12', NULL, NULL, NULL, 'quoted', ('GBP', 100), 'fix', NULL);
INSERT INTO projects (id, client_id, title, description, created_at, quoted_at, approved_at, started_at, finished_at, progress, quoted_money, quoted_ratetype, final_money) VALUES (5, 1, 'Unquoted project', 'by Wonka', '2015-07-16 00:34:56+12', NULL, NULL, NULL, NULL, 'created', NULL, NULL, NULL);


ALTER TABLE projects ENABLE TRIGGER ALL;


--
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('clients_id_seq', 2, true);


--
-- Data for Name: managers; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE managers DISABLE TRIGGER ALL;

INSERT INTO managers (id, person_id) VALUES (1, 1);


ALTER TABLE managers ENABLE TRIGGER ALL;

--
-- Name: managers_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('managers_id_seq', 1, true);


--
-- Data for Name: workers; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE workers DISABLE TRIGGER ALL;

INSERT INTO workers (id, person_id, hourly_rate) VALUES (1, 4, ('USD', 15));
INSERT INTO workers (id, person_id, hourly_rate) VALUES (2, 5, ('THB', 350));
INSERT INTO workers (id, person_id, hourly_rate) VALUES (3, 7, ('CNY', 65));


ALTER TABLE workers ENABLE TRIGGER ALL;

--
-- Data for Name: tasks; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE tasks DISABLE TRIGGER ALL;

INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (1, 1, 1, 2, 'second task', 'get bucket', '2015-07-03 00:34:56+12', '2015-07-04 00:34:56+12', '2015-07-05 00:35:56+12', '2015-07-05 00:36:56+12', 'finished');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (2, 1, 1, 1, 'first task', 'clean hands', '2015-07-03 00:34:56+12', '2015-07-04 00:34:56+12', '2015-07-05 00:34:56+12', '2015-07-05 00:35:56+12', 'finished');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (3, 1, 1, 3, 'third task', 'clean tank', '2015-07-03 00:34:56+12', '2015-07-04 00:34:56+12', '2015-07-05 00:36:56+12', '2015-07-05 03:34:56+12', 'finished');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (4, 2, 2, 1, '1st task', '3 hours', '2015-07-08 00:34:56+12', '2015-07-09 00:30:56+12', '2015-07-09 00:34:56+12', '2015-07-09 03:34:56+12', 'finished');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (5, 2, 2, 2, '2nd task', 'still working', '2015-07-08 00:34:56+12', '2015-07-09 00:30:56+12', '2015-07-09 04:00:00+12', NULL, 'started');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (9, 3, NULL, 3, 'task three', 'not claimed', '2015-07-10 00:34:56+12', NULL, NULL, NULL, 'approved');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (10, 4, NULL, 3, 'trois', 'not approved', '2015-07-13 00:34:56+12', NULL, NULL, NULL, 'quoted');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (11, 4, NULL, 2, 'deux', 'not approved', '2015-07-13 00:34:56+12', NULL, NULL, NULL, 'quoted');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (12, 4, NULL, 1, 'un', 'not approved', '2015-07-13 00:34:56+12', NULL, NULL, NULL, 'quoted');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (6, 2, 3, 3, '3rd task', 'not yet started', '2015-07-08 00:34:56+12', '2015-07-09 00:30:56+12', NULL, NULL, 'approved');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (8, 3, NULL, 2, 'task two', 'not claimed', '2015-07-10 00:34:56+12', NULL, NULL, NULL, 'approved');
INSERT INTO tasks (id, project_id, worker_id, sortid, title, description, created_at, claimed_at, started_at, finished_at, progress) VALUES (7, 3, NULL, 1, 'task one', 'not claimed', '2015-07-10 00:34:56+12', NULL, NULL, NULL, 'approved');


ALTER TABLE tasks ENABLE TRIGGER ALL;

--
-- Data for Name: notes; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE notes DISABLE TRIGGER ALL;

INSERT INTO notes (id, created_at, project_id, task_id, manager_id, client_id, worker_id, note) VALUES (1, '2015-07-07 12:34:56+12', 1, 1, NULL, 1, NULL, 'great job, Charlie!');
INSERT INTO notes (id, created_at, project_id, task_id, manager_id, client_id, worker_id, note) VALUES (2, '2015-07-07 12:45:56+12', 1, 1, NULL, NULL, 1, 'thank you sir');
INSERT INTO notes (id, created_at, project_id, task_id, manager_id, client_id, worker_id, note) VALUES (3, '2015-07-09 12:34:56+12', 2, NULL, NULL, NULL, 2, 'we do not understand');
INSERT INTO notes (id, created_at, project_id, task_id, manager_id, client_id, worker_id, note) VALUES (4, '2015-07-09 12:45:56+12', 2, NULL, NULL, 2, NULL, 'what about NOW do you not understand?!? ARRGH!');
INSERT INTO notes (id, created_at, project_id, task_id, manager_id, client_id, worker_id, note) VALUES (5, '2015-07-09 12:56:56+12', 2, NULL, 1, NULL, NULL, 'everyone calm down, we’ll get this sorted');


ALTER TABLE notes ENABLE TRIGGER ALL;

--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('notes_id_seq', 5, true);


--
-- Data for Name: payments; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE client_payments DISABLE TRIGGER ALL;

INSERT INTO client_payments (id, created_at, client_id, money, notes) VALUES (1, '2015-07-01 12:00:00+12', 1, ('USD', 50), 'payment# 4321');
INSERT INTO client_payments (id, created_at, client_id, money, notes) VALUES (2, '2015-07-05 12:00:00+12', 2, ('GBP', 100), 'payment# 5432');


ALTER TABLE client_payments ENABLE TRIGGER ALL;

SELECT pg_catalog.setval('client_payments_id_seq', 2, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('projects_id_seq', 5, true);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('tasks_id_seq', 12, true);


--
-- Data for Name: worker_payments; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE worker_payments DISABLE TRIGGER ALL;

INSERT INTO worker_payments (id, worker_id, money, created_at, notes) VALUES (1, 1, ('USD', 45.36), '2015-08-01', 'paypal id#1234');


ALTER TABLE worker_payments ENABLE TRIGGER ALL;

--
-- Data for Name: worker_charges; Type: TABLE DATA; Schema: muckwork; Owner: d50b
--

ALTER TABLE worker_charges DISABLE TRIGGER ALL;

INSERT INTO worker_charges (id, task_id, money, payment_id) VALUES (1, 2, ('USD', 0.25), 1);
INSERT INTO worker_charges (id, task_id, money, payment_id) VALUES (2, 1, ('USD', 0.25), 1);
INSERT INTO worker_charges (id, task_id, money, payment_id) VALUES (3, 3, ('USD', 44.86), 1);
INSERT INTO worker_charges (id, task_id, money, payment_id) VALUES (4, 4, ('THB', 1080), NULL);
INSERT INTO worker_charges (id, task_id, money, payment_id) VALUES (5, 7, ('USD', 15.12), NULL);
ALTER TABLE worker_charges ENABLE TRIGGER ALL;

--
-- Name: worker_charges_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('worker_charges_id_seq', 5, true);


--
-- Name: worker_payments_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('worker_payments_id_seq', 1, true);


--
-- Name: workers_id_seq; Type: SEQUENCE SET; Schema: muckwork; Owner: d50b
--

SELECT pg_catalog.setval('workers_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

