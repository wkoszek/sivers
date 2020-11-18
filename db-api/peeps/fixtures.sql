--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = peeps, pg_catalog;

--
-- Data for Name: countries; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE countries DISABLE TRIGGER ALL;

INSERT INTO countries (code, name) VALUES ('AD', 'Andorra');
INSERT INTO countries (code, name) VALUES ('AE', 'United Arab Emirates');
INSERT INTO countries (code, name) VALUES ('AF', 'Afghanistan');
INSERT INTO countries (code, name) VALUES ('AG', 'Antigua and Barbuda');
INSERT INTO countries (code, name) VALUES ('AI', 'Anguilla');
INSERT INTO countries (code, name) VALUES ('AL', 'Albania');
INSERT INTO countries (code, name) VALUES ('AM', 'Armenia');
INSERT INTO countries (code, name) VALUES ('AN', 'Netherlands Antilles');
INSERT INTO countries (code, name) VALUES ('AO', 'Angola');
INSERT INTO countries (code, name) VALUES ('AR', 'Argentina');
INSERT INTO countries (code, name) VALUES ('AS', 'American Samoa');
INSERT INTO countries (code, name) VALUES ('AT', 'Austria');
INSERT INTO countries (code, name) VALUES ('AU', 'Australia');
INSERT INTO countries (code, name) VALUES ('AW', 'Aruba');
INSERT INTO countries (code, name) VALUES ('AX', 'Åland Islands');
INSERT INTO countries (code, name) VALUES ('AZ', 'Azerbaijan');
INSERT INTO countries (code, name) VALUES ('BA', 'Bosnia and Herzegovina');
INSERT INTO countries (code, name) VALUES ('BB', 'Barbados');
INSERT INTO countries (code, name) VALUES ('BD', 'Bangladesh');
INSERT INTO countries (code, name) VALUES ('BE', 'Belgium');
INSERT INTO countries (code, name) VALUES ('BF', 'Burkina Faso');
INSERT INTO countries (code, name) VALUES ('BG', 'Bulgaria');
INSERT INTO countries (code, name) VALUES ('BH', 'Bahrain');
INSERT INTO countries (code, name) VALUES ('BI', 'Burundi');
INSERT INTO countries (code, name) VALUES ('BJ', 'Benin');
INSERT INTO countries (code, name) VALUES ('BL', 'Saint Barthélemy');
INSERT INTO countries (code, name) VALUES ('BM', 'Bermuda');
INSERT INTO countries (code, name) VALUES ('BN', 'Brunei Darussalam');
INSERT INTO countries (code, name) VALUES ('BO', 'Bolivia');
INSERT INTO countries (code, name) VALUES ('BR', 'Brazil');
INSERT INTO countries (code, name) VALUES ('BS', 'Bahamas');
INSERT INTO countries (code, name) VALUES ('BT', 'Bhutan');
INSERT INTO countries (code, name) VALUES ('BW', 'Botswana');
INSERT INTO countries (code, name) VALUES ('BY', 'Belarus');
INSERT INTO countries (code, name) VALUES ('BZ', 'Belize');
INSERT INTO countries (code, name) VALUES ('CA', 'Canada');
INSERT INTO countries (code, name) VALUES ('CC', 'Cocos Islands');
INSERT INTO countries (code, name) VALUES ('CD', 'Congo, Democratic Republic');
INSERT INTO countries (code, name) VALUES ('CF', 'Central African Republic');
INSERT INTO countries (code, name) VALUES ('CG', 'Congo');
INSERT INTO countries (code, name) VALUES ('CH', 'Switzerland');
INSERT INTO countries (code, name) VALUES ('CI', 'Côte d’Ivoire');
INSERT INTO countries (code, name) VALUES ('CK', 'Cook Islands');
INSERT INTO countries (code, name) VALUES ('CL', 'Chile');
INSERT INTO countries (code, name) VALUES ('CM', 'Cameroon');
INSERT INTO countries (code, name) VALUES ('CN', 'China');
INSERT INTO countries (code, name) VALUES ('CO', 'Colombia');
INSERT INTO countries (code, name) VALUES ('CR', 'Costa Rica');
INSERT INTO countries (code, name) VALUES ('CU', 'Cuba');
INSERT INTO countries (code, name) VALUES ('CV', 'Cape Verde');
INSERT INTO countries (code, name) VALUES ('CW', 'Curaçao');
INSERT INTO countries (code, name) VALUES ('CX', 'Christmas Island');
INSERT INTO countries (code, name) VALUES ('CY', 'Cyprus');
INSERT INTO countries (code, name) VALUES ('CZ', 'Czech Republic');
INSERT INTO countries (code, name) VALUES ('DE', 'Germany');
INSERT INTO countries (code, name) VALUES ('DJ', 'Djibouti');
INSERT INTO countries (code, name) VALUES ('DK', 'Denmark');
INSERT INTO countries (code, name) VALUES ('DM', 'Dominica');
INSERT INTO countries (code, name) VALUES ('DO', 'Dominican Republic');
INSERT INTO countries (code, name) VALUES ('DZ', 'Algeria');
INSERT INTO countries (code, name) VALUES ('EC', 'Ecuador');
INSERT INTO countries (code, name) VALUES ('EE', 'Estonia');
INSERT INTO countries (code, name) VALUES ('EG', 'Egypt');
INSERT INTO countries (code, name) VALUES ('EH', 'Western Sahara');
INSERT INTO countries (code, name) VALUES ('ER', 'Eritrea');
INSERT INTO countries (code, name) VALUES ('ES', 'Spain');
INSERT INTO countries (code, name) VALUES ('ET', 'Ethiopia');
INSERT INTO countries (code, name) VALUES ('FI', 'Finland');
INSERT INTO countries (code, name) VALUES ('FJ', 'Fiji');
INSERT INTO countries (code, name) VALUES ('FK', 'Falkland Islands');
INSERT INTO countries (code, name) VALUES ('FM', 'Micronesia');
INSERT INTO countries (code, name) VALUES ('FO', 'Faroe Islands');
INSERT INTO countries (code, name) VALUES ('FR', 'France');
INSERT INTO countries (code, name) VALUES ('GA', 'Gabon');
INSERT INTO countries (code, name) VALUES ('GB', 'United Kingdom');
INSERT INTO countries (code, name) VALUES ('GD', 'Grenada');
INSERT INTO countries (code, name) VALUES ('GE', 'Georgia');
INSERT INTO countries (code, name) VALUES ('GF', 'French Guiana');
INSERT INTO countries (code, name) VALUES ('GG', 'Guernsey');
INSERT INTO countries (code, name) VALUES ('GH', 'Ghana');
INSERT INTO countries (code, name) VALUES ('GI', 'Gibraltar');
INSERT INTO countries (code, name) VALUES ('GL', 'Greenland');
INSERT INTO countries (code, name) VALUES ('GM', 'Gambia');
INSERT INTO countries (code, name) VALUES ('GN', 'Guinea');
INSERT INTO countries (code, name) VALUES ('GP', 'Guadeloupe');
INSERT INTO countries (code, name) VALUES ('GQ', 'Equatorial Guinea');
INSERT INTO countries (code, name) VALUES ('GR', 'Greece');
INSERT INTO countries (code, name) VALUES ('GT', 'Guatemala');
INSERT INTO countries (code, name) VALUES ('GU', 'Guam');
INSERT INTO countries (code, name) VALUES ('GW', 'Guinea-Bissau');
INSERT INTO countries (code, name) VALUES ('GY', 'Guyana');
INSERT INTO countries (code, name) VALUES ('HK', 'Hong Kong');
INSERT INTO countries (code, name) VALUES ('HN', 'Honduras');
INSERT INTO countries (code, name) VALUES ('HR', 'Croatia');
INSERT INTO countries (code, name) VALUES ('HT', 'Haiti');
INSERT INTO countries (code, name) VALUES ('HU', 'Hungary');
INSERT INTO countries (code, name) VALUES ('ID', 'Indonesia');
INSERT INTO countries (code, name) VALUES ('IE', 'Ireland');
INSERT INTO countries (code, name) VALUES ('IL', 'Israel');
INSERT INTO countries (code, name) VALUES ('IM', 'Isle of Man');
INSERT INTO countries (code, name) VALUES ('IN', 'India');
INSERT INTO countries (code, name) VALUES ('IO', 'British Indian Ocean');
INSERT INTO countries (code, name) VALUES ('IQ', 'Iraq');
INSERT INTO countries (code, name) VALUES ('IR', 'Iran');
INSERT INTO countries (code, name) VALUES ('IS', 'Iceland');
INSERT INTO countries (code, name) VALUES ('IT', 'Italy');
INSERT INTO countries (code, name) VALUES ('JE', 'Jersey');
INSERT INTO countries (code, name) VALUES ('JM', 'Jamaica');
INSERT INTO countries (code, name) VALUES ('JO', 'Jordan');
INSERT INTO countries (code, name) VALUES ('JP', 'Japan');
INSERT INTO countries (code, name) VALUES ('KE', 'Kenya');
INSERT INTO countries (code, name) VALUES ('KG', 'Kyrgyzstan');
INSERT INTO countries (code, name) VALUES ('KH', 'Cambodia');
INSERT INTO countries (code, name) VALUES ('KI', 'Kiribati');
INSERT INTO countries (code, name) VALUES ('KM', 'Comoros');
INSERT INTO countries (code, name) VALUES ('KN', 'Saint Kitts and Nevis');
INSERT INTO countries (code, name) VALUES ('KP', 'Korea, North');
INSERT INTO countries (code, name) VALUES ('KR', 'Korea, South');
INSERT INTO countries (code, name) VALUES ('KW', 'Kuwait');
INSERT INTO countries (code, name) VALUES ('KY', 'Cayman Islands');
INSERT INTO countries (code, name) VALUES ('KZ', 'Kazakhstan');
INSERT INTO countries (code, name) VALUES ('LA', 'Laos');
INSERT INTO countries (code, name) VALUES ('LB', 'Lebanon');
INSERT INTO countries (code, name) VALUES ('LC', 'Saint Lucia');
INSERT INTO countries (code, name) VALUES ('LI', 'Liechtenstein');
INSERT INTO countries (code, name) VALUES ('LK', 'Sri Lanka');
INSERT INTO countries (code, name) VALUES ('LR', 'Liberia');
INSERT INTO countries (code, name) VALUES ('LS', 'Lesotho');
INSERT INTO countries (code, name) VALUES ('LT', 'Lithuania');
INSERT INTO countries (code, name) VALUES ('LU', 'Luxembourg');
INSERT INTO countries (code, name) VALUES ('LV', 'Latvia');
INSERT INTO countries (code, name) VALUES ('LY', 'Libyan Arab Jamahiriya');
INSERT INTO countries (code, name) VALUES ('MA', 'Morocco');
INSERT INTO countries (code, name) VALUES ('MC', 'Monaco');
INSERT INTO countries (code, name) VALUES ('MD', 'Moldova, Republic of');
INSERT INTO countries (code, name) VALUES ('ME', 'Montenegro');
INSERT INTO countries (code, name) VALUES ('MF', 'Saint Martin (French)');
INSERT INTO countries (code, name) VALUES ('MG', 'Madagascar');
INSERT INTO countries (code, name) VALUES ('MH', 'Marshall Islands');
INSERT INTO countries (code, name) VALUES ('MK', 'Macedonia');
INSERT INTO countries (code, name) VALUES ('ML', 'Mali');
INSERT INTO countries (code, name) VALUES ('MM', 'Myanmar');
INSERT INTO countries (code, name) VALUES ('MN', 'Mongolia');
INSERT INTO countries (code, name) VALUES ('MO', 'Macao');
INSERT INTO countries (code, name) VALUES ('MP', 'Northern Mariana Islands');
INSERT INTO countries (code, name) VALUES ('MQ', 'Martinique');
INSERT INTO countries (code, name) VALUES ('MR', 'Mauritania');
INSERT INTO countries (code, name) VALUES ('MS', 'Montserrat');
INSERT INTO countries (code, name) VALUES ('MT', 'Malta');
INSERT INTO countries (code, name) VALUES ('MU', 'Mauritius');
INSERT INTO countries (code, name) VALUES ('MV', 'Maldives');
INSERT INTO countries (code, name) VALUES ('MW', 'Malawi');
INSERT INTO countries (code, name) VALUES ('MX', 'Mexico');
INSERT INTO countries (code, name) VALUES ('MY', 'Malaysia');
INSERT INTO countries (code, name) VALUES ('MZ', 'Mozambique');
INSERT INTO countries (code, name) VALUES ('NA', 'Namibia');
INSERT INTO countries (code, name) VALUES ('NC', 'New Caledonia');
INSERT INTO countries (code, name) VALUES ('NE', 'Niger');
INSERT INTO countries (code, name) VALUES ('NF', 'Norfolk Island');
INSERT INTO countries (code, name) VALUES ('NG', 'Nigeria');
INSERT INTO countries (code, name) VALUES ('NI', 'Nicaragua');
INSERT INTO countries (code, name) VALUES ('NL', 'Netherlands');
INSERT INTO countries (code, name) VALUES ('NO', 'Norway');
INSERT INTO countries (code, name) VALUES ('NP', 'Nepal');
INSERT INTO countries (code, name) VALUES ('NR', 'Nauru');
INSERT INTO countries (code, name) VALUES ('NU', 'Niue');
INSERT INTO countries (code, name) VALUES ('NZ', 'New Zealand');
INSERT INTO countries (code, name) VALUES ('OM', 'Oman');
INSERT INTO countries (code, name) VALUES ('PA', 'Panama');
INSERT INTO countries (code, name) VALUES ('PE', 'Peru');
INSERT INTO countries (code, name) VALUES ('PF', 'French Polynesia');
INSERT INTO countries (code, name) VALUES ('PG', 'Papua New Guinea');
INSERT INTO countries (code, name) VALUES ('PH', 'Philippines');
INSERT INTO countries (code, name) VALUES ('PK', 'Pakistan');
INSERT INTO countries (code, name) VALUES ('PL', 'Poland');
INSERT INTO countries (code, name) VALUES ('PM', 'Saint Pierre and Miquelon');
INSERT INTO countries (code, name) VALUES ('PN', 'Pitcairn');
INSERT INTO countries (code, name) VALUES ('PR', 'Puerto Rico');
INSERT INTO countries (code, name) VALUES ('PS', 'Palestinian Territory');
INSERT INTO countries (code, name) VALUES ('PT', 'Portugal');
INSERT INTO countries (code, name) VALUES ('PW', 'Palau');
INSERT INTO countries (code, name) VALUES ('PY', 'Paraguay');
INSERT INTO countries (code, name) VALUES ('QA', 'Qatar');
INSERT INTO countries (code, name) VALUES ('RE', 'Réunion');
INSERT INTO countries (code, name) VALUES ('RO', 'Romania');
INSERT INTO countries (code, name) VALUES ('RS', 'Serbia');
INSERT INTO countries (code, name) VALUES ('RU', 'Russian Federation');
INSERT INTO countries (code, name) VALUES ('RW', 'Rwanda');
INSERT INTO countries (code, name) VALUES ('SA', 'Saudi Arabia');
INSERT INTO countries (code, name) VALUES ('SB', 'Solomon Islands');
INSERT INTO countries (code, name) VALUES ('SC', 'Seychelles');
INSERT INTO countries (code, name) VALUES ('SD', 'Sudan');
INSERT INTO countries (code, name) VALUES ('SE', 'Sweden');
INSERT INTO countries (code, name) VALUES ('SG', 'Singapore');
INSERT INTO countries (code, name) VALUES ('SH', 'Saint Helena');
INSERT INTO countries (code, name) VALUES ('SI', 'Slovenia');
INSERT INTO countries (code, name) VALUES ('SJ', 'Svalbard and Jan Mayen');
INSERT INTO countries (code, name) VALUES ('SK', 'Slovakia');
INSERT INTO countries (code, name) VALUES ('SL', 'Sierra Leone');
INSERT INTO countries (code, name) VALUES ('SM', 'San Marino');
INSERT INTO countries (code, name) VALUES ('SN', 'Senegal');
INSERT INTO countries (code, name) VALUES ('SO', 'Somalia');
INSERT INTO countries (code, name) VALUES ('SR', 'Suriname');
INSERT INTO countries (code, name) VALUES ('SS', 'South Sudan');
INSERT INTO countries (code, name) VALUES ('ST', 'Sao Tome and Principe');
INSERT INTO countries (code, name) VALUES ('SV', 'El Salvador');
INSERT INTO countries (code, name) VALUES ('SX', 'Sint Maarten (Dutch)');
INSERT INTO countries (code, name) VALUES ('SY', 'Syrian Arab Republic');
INSERT INTO countries (code, name) VALUES ('SZ', 'Swaziland');
INSERT INTO countries (code, name) VALUES ('TC', 'Turks and Caicos Islands');
INSERT INTO countries (code, name) VALUES ('TD', 'Chad');
INSERT INTO countries (code, name) VALUES ('TG', 'Togo');
INSERT INTO countries (code, name) VALUES ('TH', 'Thailand');
INSERT INTO countries (code, name) VALUES ('TJ', 'Tajikistan');
INSERT INTO countries (code, name) VALUES ('TK', 'Tokelau');
INSERT INTO countries (code, name) VALUES ('TL', 'Timor-Leste');
INSERT INTO countries (code, name) VALUES ('TM', 'Turkmenistan');
INSERT INTO countries (code, name) VALUES ('TN', 'Tunisia');
INSERT INTO countries (code, name) VALUES ('TO', 'Tonga');
INSERT INTO countries (code, name) VALUES ('TR', 'Turkey');
INSERT INTO countries (code, name) VALUES ('TT', 'Trinidad and Tobago');
INSERT INTO countries (code, name) VALUES ('TV', 'Tuvalu');
INSERT INTO countries (code, name) VALUES ('TW', 'Taiwan');
INSERT INTO countries (code, name) VALUES ('TZ', 'Tanzania');
INSERT INTO countries (code, name) VALUES ('UA', 'Ukraine');
INSERT INTO countries (code, name) VALUES ('UG', 'Uganda');
INSERT INTO countries (code, name) VALUES ('US', 'United States');
INSERT INTO countries (code, name) VALUES ('UY', 'Uruguay');
INSERT INTO countries (code, name) VALUES ('UZ', 'Uzbekistan');
INSERT INTO countries (code, name) VALUES ('VC', 'Saint Vincent & Grenadines');
INSERT INTO countries (code, name) VALUES ('VE', 'Venezuela');
INSERT INTO countries (code, name) VALUES ('VG', 'Virgin Islands, British');
INSERT INTO countries (code, name) VALUES ('VI', 'Virgin Islands, U.S.');
INSERT INTO countries (code, name) VALUES ('VN', 'Vietnam');
INSERT INTO countries (code, name) VALUES ('VU', 'Vanuatu');
INSERT INTO countries (code, name) VALUES ('WF', 'Wallis and Futuna');
INSERT INTO countries (code, name) VALUES ('WS', 'Samoa');
INSERT INTO countries (code, name) VALUES ('YE', 'Yemen');
INSERT INTO countries (code, name) VALUES ('YT', 'Mayotte');
INSERT INTO countries (code, name) VALUES ('ZA', 'South Africa');
INSERT INTO countries (code, name) VALUES ('ZM', 'Zambia');
INSERT INTO countries (code, name) VALUES ('ZW', 'Zimbabwe');


ALTER TABLE countries ENABLE TRIGGER ALL;

--
-- Data for Name: people; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE people DISABLE TRIGGER ALL;

INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (1, 'derek@sivers.org', 'Derek Sivers', 'Derek', 'abcd', '$2a$08$0yI7Vpn3UNEf5q.muDgLL.y5GJRM5ak2awUOnd9z9ZCBFoCz0/Rfy', 'yTAy', NULL, '50POP LLC', 'Singapore', NULL, 'SG', 'This is me.', 0, 'all', 'derek', '1994-11-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (2, 'willy@wonka.com', 'Willy Wonka', 'Mr. Wonka', 'efgh', '$2a$08$3UjNlK6PbXMXC7Rh.EVIFeRcvmij/b8bSfNZ.MwwmD8QtQ0sy2zje', 'R5Gf', NULL, 'Wonka Chocolate Inc', 'Hershey', 'PA', 'US', NULL, 2, 'some', NULL, '2000-01-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (3, 'veruca@salt.com', 'Veruca Salt', 'Veruca', 'ijkl', '$2a$08$GcHJDheKQR7zu8qTr1anz.WpLoVPbZG6dA/9zaUkowcypCczUYozy', '8gcr', NULL, 'Daddy Empires Ltd', 'London', 'England', 'GB', NULL, 4, NULL, NULL, '2010-01-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (4, 'charlie@bucket.org', 'Charlie Buckets', 'Charlie', 'mnop', '$2a$08$Nf7VymjLuGGUhMl9lGTPAO0GrNq0bE5yTVMyimlFR2f7SmTMNxN46', 'AgA2', NULL, NULL, 'Hershey', 'PA', 'US', NULL, 0, 'all', NULL, '2010-09-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (5, 'oompa@loompa.mm', 'Oompa Loompa', 'Oompa Loompa', 'qrst', '$2a$08$vr40BeQAbNFkKaes4WPPw.lCQKPsyzAsNPRVQ2bPgVVatyvtwSKSO', 'LYtp', NULL, NULL, 'Hershey', 'PA', 'US', NULL, 0, NULL, NULL, '2010-10-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (6, 'augustus@gloop.de', 'Augustus Gloop', 'Master Gloop', NULL, '$2a$08$JmphXF9YeW7Fi2IQVUnZtenBU2Ftacz454V1B1Ort4/VZhFgpMzWO', 'AKyv', NULL, NULL, 'Munich', NULL, 'DE', NULL, 0, 'some', NULL, '2010-11-01');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (7, 'gong@li.cn', '巩俐', '巩俐', NULL, '$2a$08$x/C0JU7r7Obp2Ar/1G0kz.t.mrW/r0Nan0sDggw3wjjBdr6jvcpge', 'FBvY', NULL, 'Gong Li', 'Shanghai', NULL, 'CN', NULL, 2, NULL, 'translator', '2010-12-12');
INSERT INTO people (id, email, name, address, public_id, hashpass, lopass, newpass, company, city, state, country, notes, email_count, listype, categorize_as, created_at) VALUES (8, 'yoko@ono.com', 'Yoko Ono', 'Ono-San', NULL, '$2a$08$3yMZNGqUsUH3bQaCE7Rmbeay6FHW/Us2axycwUMDsvGKSDGlVfZPS', 'uUyS', NULL, 'yoko@lennon.com', 'Tokyo', NULL, 'JP', NULL, 0, NULL, 'translator', '2010-12-12');


ALTER TABLE people ENABLE TRIGGER ALL;

--
-- Data for Name: atkeys; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE atkeys DISABLE TRIGGER ALL;

INSERT INTO atkeys (atkey, description) VALUES ('patient', 'does not need it now');
INSERT INTO atkeys (atkey, description) VALUES ('verbose', 'uses lots of words to communicate');
INSERT INTO atkeys (atkey, description) VALUES ('available', 'free to work or do new things');


ALTER TABLE atkeys ENABLE TRIGGER ALL;

--
-- Data for Name: attributes; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE attributes DISABLE TRIGGER ALL;

INSERT INTO attributes (person_id, attribute, plusminus) VALUES (3, 'patient', false);
INSERT INTO attributes (person_id, attribute, plusminus) VALUES (3, 'verbose', false);
INSERT INTO attributes (person_id, attribute, plusminus) VALUES (4, 'patient', true);
INSERT INTO attributes (person_id, attribute, plusminus) VALUES (6, 'available', true);
INSERT INTO attributes (person_id, attribute, plusminus) VALUES (6, 'verbose', false);


ALTER TABLE attributes ENABLE TRIGGER ALL;

--
-- Data for Name: emailers; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE emailers DISABLE TRIGGER ALL;

INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (1, 1, true, '{ALL}', '{ALL}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (2, 4, false, '{ALL}', '{ALL}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (3, 6, false, '{sivers}', '{translator,not-derek}');
INSERT INTO emailers (id, person_id, admin, profiles, categories) VALUES (4, 7, true, '{woodegg}', '{ALL}');


ALTER TABLE emailers ENABLE TRIGGER ALL;

--
-- Data for Name: emails; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE emails DISABLE TRIGGER ALL;

INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (1, 2, 'sivers', 'sivers', '2013-07-18 15:55:03', 1, '2013-07-20 03:42:19', 1, '2013-07-20 03:44:01', 1, NULL, 3, 'willy@wonka.com', 'Will Wonka', 'you coming by?', 'To: Derek Sivers <derek@sivers.org>
From: Will Wonka <willya@wonka.com>
Message-ID: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>
Subject: you coming by?
Date: Wed, 17 Jul 2013 23:42:59 -0400', 'Dude -

Seriously. You coming by sometime soon?

- Will', '8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (2, 7, 'sivers', 'translator', '2013-07-18 15:55:03', 3, '2013-07-20 03:45:19', 3, '2013-07-20 03:47:01', 3, NULL, 4, 'gong@li.cn', 'Gong Li', 'translations almost done', 'To: Derek Sivers <derek@sivers.org>
From: Gong Li <gong@li.cn>
Message-ID: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>
Subject: translations almost done
Date: Thu, 18 Jul 2013 10:42:59 -0400', 'Hello Mr. Sivers -

Busy raising these red lanterns, but I''m almost done with the translation.

巩俐', 'CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (3, 2, 'sivers', 'sivers', '2013-07-20 03:47:01', 1, '2013-07-20 03:47:01', 1, '2013-07-20 03:47:01', 1, 1, NULL, 'willy@wonka.com', 'Will Wonka', 're: you coming by?', 'References: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>
In-Reply-To: <8w2mb4flbgdd0d95x35tk4ln.1374118952478@email.android.com>', 'Hi Will -

Yep. On my way ASAP.

--
Derek Sivers  derek@sivers.org  http://sivers.org

> Dude -
> Seriously. You coming by sometime soon?
> - Will', '20130719234701.2@sivers.org', true, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (4, 7, 'sivers', 'translator', '2013-07-20 03:47:01', 3, '2013-07-20 03:47:01', 3, '2013-07-20 03:47:01', 3, 2, NULL, 'gong@li.cn', 'Gong Li', 're: translations almost done', 'References: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>
In-Reply-To: <CABk7SeW6+FaqxOUwHNdiaR2AdxQBTY1275uC0hdkA0kLPpKPVg@mail.li.cn>', 'Hi Gong -

Thank you for the update.

--
Derek Sivers  derek@sivers.org  http://sivers.org/

> Hello Mr. Sivers -
> Busy raising these red lanterns, but I''m almost done with the translation.
> 巩俐', '20130719235701.7@sivers.org', NULL, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (5, NULL, 'sivers', 'fix-client', '2013-07-20 15:42:03', 2, NULL, NULL, NULL, NULL, NULL, NULL, 'new@stranger.com', 'New Stranger', 'random question', 'To: Derek Sivers <derek@sivers.org>
From: New Stranger <new@stranger.com>
Message-ID: <COL401-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl>
Subject: random question
Date: Fri, 20 Jul 2013 11:42:59 -0400', 'Derek -

I have a question

- Stranger', 'COL401-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (6, 3, 'woodegg', 'woodegg', '2014-05-20 15:55:03', 4, '2014-05-21 03:42:19', 4, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I want that Wood Egg book now', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7A@mail.gmail.com>
Subject: I want it now
Date: Tue, 20 May 2014 11:42:59 -0400', 'Hi Wood Egg -

Now!

- v', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7A@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (7, 3, 'woodegg', 'not-derek', '2014-05-29 15:55:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I said now!!!', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7B@mail.gmail.com>
Subject: I said now!!!
Date: Thurs, 29 May 2014 11:42:59 -0400', 'I said now!!! I changed my email from veruca@salt.com to veruca@salt.net. My new sites are salt.net and https://something.travel/salt  You already have www.salt.com', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7B@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (8, 3, 'woodegg', 'woodegg', '2014-05-29 15:56:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'I refuse to wait', 'To: Wood Egg <we@woodegg.com>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7C@mail.gmail.com>
Subject: I refuse to wait
Date: Thurs, 29 May 2014 11:44:59 -0400', 'I refuse to wait', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7C@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (9, 3, 'sivers', 'derek', '2014-05-29 15:57:03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 'veruca@salt.com', 'Veruca Salt', 'getting personal', 'To: Derek Sivers <derek@sivers.org>
From: Veruca Salt <veruca@salt.com>
Message-ID: <CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7D@mail.gmail.com>
Subject: getting personal
Date: Thurs, 29 May 2014 11:45:59 -0400', 'Wood Egg is not replying to my last three emails!', 'CAGfCXh-fw-xxC_traMbbKTUdpcuq=N774ya=LTn0vejrAPVm7D@mail.gmail.com', false, NULL);
INSERT INTO emails (id, person_id, profile, category, created_at, created_by, opened_at, opened_by, closed_at, closed_by, reference_id, answer_id, their_email, their_name, subject, headers, body, message_id, outgoing, flag) VALUES (10, NULL, 'sivers', 'fix-client', '2013-07-20 15:42:03', 2, NULL, NULL, NULL, NULL, NULL, NULL, 'oompaloompa@outlook.com', 'Oompa Loompa', 'remember me?', 'To: Derek Sivers <derek@sivers.org>
From: Oompa Loompa <oompaloompa@outlook.com>
Message-ID: <ABC123-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl>
Subject: remember me?
Date: Fri, 20 Jul 2013 11:42:59 -0400', 'Derek -

Remember me?

- Ooompa, from my new email address.', 'ABC123-EAS301156C36A4AA949CA6B320BA7C1@phx.gbl', false, NULL);


ALTER TABLE emails ENABLE TRIGGER ALL;

--
-- Data for Name: email_attachments; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE email_attachments DISABLE TRIGGER ALL;

INSERT INTO email_attachments (id, email_id, mime_type, filename, bytes) VALUES (1, 9, 'image/jpeg', '20140529-abcd-angry.jpg', 54321);
INSERT INTO email_attachments (id, email_id, mime_type, filename, bytes) VALUES (2, 9, 'image/jpeg', '20140529-efgh-mad.jpg', 65432);


ALTER TABLE email_attachments ENABLE TRIGGER ALL;

--
-- Name: email_attachments_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('email_attachments_id_seq', 2, true);


--
-- Name: emailers_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('emailers_id_seq', 4, true);


--
-- Name: emails_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('emails_id_seq', 10, true);


--
-- Data for Name: formletters; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE formletters DISABLE TRIGGER ALL;

INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (3, NULL, 'three', 'blah', NULL, 'meh', '2014-12-22');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (4, NULL, 'four', 'blah', NULL, 'meh', '2014-12-22');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (5, 'f', 'five', 'blah', NULL, 'meh', '2014-12-22');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (6, 's', 'six', 'blah', NULL, 'meh', '2014-12-22');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (7, NULL, 'muckcs', '', 'muckwork signup', 'https://c.muckwork.com/signup/{id}/{newpass}', '2016-06-13');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (2, 't', 'two', 'replace braces only', '{address} thanks address', 'Hi {address}. Thank you for buying something on somedate. We will ship it to your address.', '2014-12-22');
INSERT INTO formletters (id, accesskey, title, explanation, subject, body, created_at) VALUES (1, '1', 'one', 'use for one', '{address} your email', 'Your email is {email}. Here is your URL: https://data.sivers.org/newpass/{id}/{newpass} OK?', '2014-12-22');


ALTER TABLE formletters ENABLE TRIGGER ALL;

--
-- Name: formletters_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('formletters_id_seq', 7, true);


--
-- Data for Name: inkeys; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE inkeys DISABLE TRIGGER ALL;

INSERT INTO inkeys (inkey, description) VALUES ('mandarin', 'speaks/writes Mandarin Chinese');
INSERT INTO inkeys (inkey, description) VALUES ('translation', 'does translation from English to another language');
INSERT INTO inkeys (inkey, description) VALUES ('lanterns', 'use for testing email body parsing email 2 person 7');
INSERT INTO inkeys (inkey, description) VALUES ('chocolate', 'some make it. many eat it.');


ALTER TABLE inkeys ENABLE TRIGGER ALL;

--
-- Data for Name: interests; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE interests DISABLE TRIGGER ALL;

INSERT INTO interests (person_id, interest, expert) VALUES (2, 'chocolate', true);
INSERT INTO interests (person_id, interest, expert) VALUES (1, 'mandarin', false);
INSERT INTO interests (person_id, interest, expert) VALUES (1, 'translation', false);
INSERT INTO interests (person_id, interest, expert) VALUES (5, 'chocolate', true);
INSERT INTO interests (person_id, interest, expert) VALUES (6, 'chocolate', false);
INSERT INTO interests (person_id, interest, expert) VALUES (3, 'chocolate', false);
INSERT INTO interests (person_id, interest, expert) VALUES (7, 'mandarin', true);
INSERT INTO interests (person_id, interest, expert) VALUES (7, 'translation', true);


ALTER TABLE interests ENABLE TRIGGER ALL;

--
-- Data for Name: logins; Type: TABLE DATA; Schema: peeps; Owner: d50b
--
INSERT INTO logins(cookie, person_id, domain) VALUES('NOugliNn5k67qJUuXEk8UGr6SCMAA645', 1, 'sivers.org');

--
-- Name: people_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('people_id_seq', 8, true);


--
-- Data for Name: stats; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE stats DISABLE TRIGGER ALL;

INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (1, 1, 'listype', 'all', '2008-01-01');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (2, 1, 'twitter', '987654321 = sivers', '2010-01-01');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (3, 2, 'listype', 'some', '2011-03-15');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (4, 2, 'musicthoughts', 'clicked', '2011-03-16');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (5, 1, 'ayw', 'a', '2013-07-25');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (6, 6, 'woodegg-mn', 'interview', '2013-09-09');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (7, 6, 'woodegg-bio', 'Augustus has done a lot of business in Mongolia, importing chocolate.', '2013-09-09');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (8, 5, 'media', 'interview', '2014-12-23');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (9, 1, 'now-liner', 'I make useful things', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (10, 1, 'now-read', 'Wisdom of No Escape', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (11, 1, 'now-thought', 'You can change how you feel', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (12, 1, 'now-title', 'Writer, programmer, entrepreneur', '2015-11-10');
INSERT INTO stats (id, person_id, statkey, statvalue, created_at) VALUES (13, 1, 'now-why', 'Learning for the sake of creating for the sake of learning for the sake of creating.', '2015-11-10');


ALTER TABLE stats ENABLE TRIGGER ALL;

--
-- Name: stats_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('stats_id_seq', 13, true);


--
-- Data for Name: urls; Type: TABLE DATA; Schema: peeps; Owner: d50b
--

ALTER TABLE urls DISABLE TRIGGER ALL;

INSERT INTO urls (id, person_id, url, main) VALUES (1, 1, 'https://twitter.com/sivers', false);
INSERT INTO urls (id, person_id, url, main) VALUES (2, 1, 'http://sivers.org/', true);
INSERT INTO urls (id, person_id, url, main) VALUES (3, 2, 'http://www.wonka.com/', true);
INSERT INTO urls (id, person_id, url, main) VALUES (4, 2, 'http://cdbaby.com/cd/wonka', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (5, 2, 'https://twitter.com/wonka', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (6, 3, 'http://salt.com/', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (7, 3, 'http://facebook.com/salt', NULL);
INSERT INTO urls (id, person_id, url, main) VALUES (8, 5, 'http://oompa.loompa', NULL);


ALTER TABLE urls ENABLE TRIGGER ALL;

--
-- Name: urls_id_seq; Type: SEQUENCE SET; Schema: peeps; Owner: d50b
--

SELECT pg_catalog.setval('urls_id_seq', 8, true);



INSERT INTO tweets (id, entire, created_at, person_id, handle, message, reference_id, seen) VALUES (40583764836353, '{"id": 40583764836353, "geo": null, "lang": "en", "text": "@Cat @Claire @_xx @sivers @YouTube love this", "user": {"id": 326810572, "url": null, "lang": "en", "name": "J Buckets", "id_str": "326810572", "entities": {"description": {"urls": []}}, "location": "Chapel-en-le-Frith, England", "verified": false, "following": false, "protected": false, "time_zone": "London", "created_at": "Thu Jun 30 14:41:40 +0000 2011", "utc_offset": 3600, "description": "Yep", "geo_enabled": true, "screen_name": "JBuckets3", "listed_count": 293, "friends_count": 4293, "is_translator": false, "notifications": false, "statuses_count": 18938, "default_profile": false, "followers_count": 4292, "favourites_count": 19545, "profile_image_url": "http://pbs.twimg.com/profile_images/684296743840804864/xqnFUx_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/326810572/1463433508", "profile_link_color": "333333", "profile_text_color": "ED850E", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": true, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": true, "profile_image_url_https": "https://pbs.twimg.com/profile_images/684296743840804864/9HtqnFUx_normal.jpg", "profile_background_color": "ED850E", "profile_sidebar_fill_color": "DDEEF6", "profile_background_image_url": "http://pbs.twimg.com/profile_background_images/480020373467963392/oFz_GB70.png", "profile_sidebar_border_color": "000000", "profile_use_background_image": false, "profile_background_image_url_https": "https://pbs.twimg.com/profile_background_images/480020373467963392/oFz_GB70.png"}, "place": {"id": "263010b450985b01", "url": "https://api.twitter.com/1.1/geo/id/263010b450985b01.json", "name": "Chapel-en-le-Frith", "country": "United Kingdom", "full_name": "Chapel-en-le-Frith, England", "attributes": {}, "place_type": "city", "bounding_box": {"type": "Polygon", "coordinates": [[[-1.9375348, 53.3144534], [-1.8981014, 53.3144534], [-1.8981014, 53.3407651], [-1.9375348, 53.3407651]]]}, "country_code": "GB", "contained_within": []}, "id_str": "40583764836353", "source": "<a href=\"http://twitter.com/download/android\" rel=\"nofollow\">Twitter for Android</a>", "entities": {"urls": [], "symbols": [], "hashtags": [], "user_mentions": [{"id": 1267932944, "name": "Cath H", "id_str": "1267932944", "indices": [0, 11], "screen_name": "Cat"}, {"id": 20451052, "name": "Claire ", "id_str": "20451052", "indices": [12, 24], "screen_name": "Claire"}, {"id": 760824000520003584, "name": "FrimleyHealthL&D", "id_str": "760824000520003584", "indices": [25, 41], "screen_name": "_xx"}, {"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [42, 49], "screen_name": "sivers"}, {"id": 10228272, "name": "YouTube", "id_str": "10228272", "indices": [50, 58], "screen_name": "YouTube"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Wed Aug 17 22:34:42 +0000 2016", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 0, "is_quote_status": false, "in_reply_to_user_id": 1267932944, "in_reply_to_status_id": 13562397593600, "in_reply_to_screen_name": "Cat", "in_reply_to_user_id_str": "1267932944", "in_reply_to_status_id_str": "13562397593600"}', '2016-08-18 10:34:42', NULL, 'JBuckets3', '@Cat @Claire @_xx @sivers @YouTube love this', 13562397593600, NULL);
INSERT INTO tweets (id, entire, created_at, person_id, handle, message, reference_id, seen) VALUES (13562397593600, '{"id": 13562397593600, "geo": null, "lang": "en", "text": "@Claire can''t use that phrase and not bring out this gem! https://t.co/PfjvhuExWR #firstfollower via @sivers", "user": {"id": 1267932944, "url": null, "lang": "en", "name": "Cath H", "id_str": "1267932944", "entities": {"description": {"urls": []}}, "location": "", "verified": false, "following": false, "protected": false, "time_zone": null, "created_at": "Thu Mar 14 20:32:13 +0000 2013", "utc_offset": null, "description": "Views my own", "geo_enabled": false, "screen_name": "Cat", "listed_count": 90, "friends_count": 719, "is_translator": false, "notifications": false, "statuses_count": 7782, "default_profile": true, "followers_count": 707, "favourites_count": 4579, "profile_image_url": "http://pbs.twimg.com/profile_images/98719576969216/WTkhg_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/1267932944/1463552675", "profile_link_color": "0084B4", "profile_text_color": "333333", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": false, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/98719576969216/WTkhg_normal.jpg", "profile_background_color": "C0DEED", "profile_sidebar_fill_color": "DDEEF6", "profile_background_image_url": "http://abs.twimg.com/images/themes/theme1/bg.png", "profile_sidebar_border_color": "C0DEED", "profile_use_background_image": true, "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme1/bg.png"}, "place": null, "id_str": "13562397593600", "source": "<a href=\"http://twitter.com/download/android\" rel=\"nofollow\">Twitter for Android</a>", "entities": {"urls": [{"url": "https://t.co/PfjvhuExWR", "indices": [80, 103], "display_url": "youtu.be/fW8amMCVAJQ", "expanded_url": "https://youtu.be/fW8amMCVAJQ"}], "symbols": [], "hashtags": [{"text": "firstfollower", "indices": [104, 118]}], "user_mentions": [{"id": 20451052, "name": "Claire ", "id_str": "20451052", "indices": [0, 12], "screen_name": "Claire"}, {"id": 760824000520003584, "name": "FrimleyHealthL&D", "id_str": "760824000520003584", "indices": [13, 29], "screen_name": "_xx"}, {"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [123, 130], "screen_name": "sivers"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Wed Aug 17 20:47:19 +0000 2016", "coordinates": null, "contributors": null, "retweet_count": 1, "favorite_count": 3, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": 20451052, "in_reply_to_status_id": null, "in_reply_to_screen_name": "Claire", "in_reply_to_user_id_str": "20451052", "in_reply_to_status_id_str": null}', '2016-08-18 08:47:19', NULL, 'Cat', '@Claire @_xx can''t use that phrase and not bring out this gem! https://youtu.be/fW8amMCVAJQ #firstfollower via @sivers', NULL, NULL);
INSERT INTO tweets (id, entire, created_at, person_id, handle, message, reference_id, seen) VALUES (63322672267265, '{"id": 63322672267265, "geo": null, "lang": "en", "text": "In the end, it''s about what you want to be, not what you want to have. -  @sivers #quote", "user": {"id": 2197529854, "url": "http://t.co/BPHueI9FQH", "lang": "en", "name": "Mind the #Quote", "id_str": "2197529854", "entities": {"url": {"urls": [{"url": "http://t.co/BPHueI9FQH", "indices": [0, 22], "display_url": "salt.com", "expanded_url": "http://www.salt.com"}]}, "description": {"urls": [{"url": "https://t.co/icJPKGsrIw", "indices": [98, 121], "display_url": "tweetjukebox.com", "expanded_url": "http://tweetjukebox.com"}]}}, "location": "London, England", "verified": false, "following": false, "protected": false, "time_zone": null, "created_at": "Wed Nov 27 05:47:44 +0000 2013", "utc_offset": null, "description": "hey #quotes. Finding, creating  and sharing them. Have a great #quote - pls share it! Powered by https://t.co/icJPKGsrIw", "geo_enabled": true, "screen_name": "salt", "listed_count": 865, "friends_count": 7340, "is_translator": false, "notifications": false, "statuses_count": 49724, "default_profile": true, "followers_count": 7522, "favourites_count": 316, "profile_image_url": "http://pbs.twimg.com/profile_images/663964837450547200/fpEiirWQ_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/2197529854/1447145074", "profile_link_color": "0084B4", "profile_text_color": "333333", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": false, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/663964837450547200/fpEiirWQ_normal.jpg", "profile_background_color": "C0DEED", "profile_sidebar_fill_color": "DDEEF6", "profile_background_image_url": "http://abs.twimg.com/images/themes/theme1/bg.png", "profile_sidebar_border_color": "C0DEED", "profile_use_background_image": true, "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme1/bg.png"}, "place": null, "id_str": "63322672267265", "source": "<a href=\"https://www.socialjukebox.com\" rel=\"nofollow\">The Social Jukebox</a>", "entities": {"urls": [], "symbols": [], "hashtags": [{"text": "quote", "indices": [82, 88]}], "user_mentions": [{"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [74, 81], "screen_name": "sivers"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Thu Aug 18 00:05:03 +0000 2016", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 0, "is_quote_status": false, "in_reply_to_user_id": null, "in_reply_to_status_id": null, "in_reply_to_screen_name": null, "in_reply_to_user_id_str": null, "in_reply_to_status_id_str": null}', '2016-08-18 12:05:03', NULL, 'salt', 'In the end, it''s about what you want to be, not what you want to have. -  @sivers #quote', NULL, NULL);
INSERT INTO tweets (id, entire, created_at, person_id, handle, message, reference_id, seen) VALUES (58297459929088, '{"id": 58297459929088, "geo": null, "lang": "en", "text": "hey @sivers", "user": {"id": 576569, "url": "https://t.co/7nYvrp", "lang": "en", "name": "Willy Wonka", "id_str": "576569", "entities": {"url": {"urls": [{"url": "https://t.co/7nYvrp", "indices": [0, 23], "display_url": "wonka.weebly.com", "expanded_url": "http://wonka.weebly.com/"}]}, "description": {"urls": []}}, "location": "Maryland, USA", "verified": false, "following": false, "protected": false, "time_zone": null, "created_at": "Sat Nov 22 02:41:43 +0000 2014", "utc_offset": null, "description": "is me", "geo_enabled": true, "screen_name": "wonka", "listed_count": 30, "friends_count": 1223, "is_translator": false, "notifications": false, "statuses_count": 379, "default_profile": false, "followers_count": 682, "favourites_count": 795, "profile_image_url": "http://pbs.twimg.com/profile_images/10393071407104/BnYPo_normal.jpg", "profile_banner_url": "https://pbs.twimg.com/profile_banners/576569/1470870030", "profile_link_color": "1B95E0", "profile_text_color": "000000", "follow_request_sent": false, "contributors_enabled": false, "has_extended_profile": false, "default_profile_image": false, "is_translation_enabled": false, "profile_background_tile": false, "profile_image_url_https": "https://pbs.twimg.com/profile_images/10393071407104/BnYPo_normal.jpg", "profile_background_color": "000000", "profile_sidebar_fill_color": "000000", "profile_background_image_url": "http://abs.twimg.com/images/themes/theme1/bg.png", "profile_sidebar_border_color": "000000", "profile_use_background_image": false, "profile_background_image_url_https": "https://abs.twimg.com/images/themes/theme1/bg.png"}, "place": null, "id_str": "58297459929088", "source": "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>", "entities": {"urls": [{"url": "https://t.co/9bJrC6CzhO", "indices": [70, 93], "display_url": "youtube.com/watch?v=xcmI5S…", "expanded_url": "https://www.youtube.com/watch?v=xcmI5SSQLmE"}], "symbols": [], "hashtags": [{"text": "GooleEi", "indices": [61, 69]}], "user_mentions": [{"id": 2206131, "name": "Derek Sivers", "id_str": "2206131", "indices": [4, 10], "screen_name": "sivers"}]}, "favorited": false, "retweeted": false, "truncated": false, "created_at": "Wed Aug 17 23:45:05 +0000 2016", "coordinates": null, "contributors": null, "retweet_count": 0, "favorite_count": 2, "is_quote_status": false, "possibly_sensitive": false, "in_reply_to_user_id": 408298, "in_reply_to_status_id": null, "in_reply_to_screen_name": "foof", "in_reply_to_user_id_str": "408298", "in_reply_to_status_id_str": null}', '2016-08-18 11:45:05', 2, 'wonka', 'hey @sivers', NULL, NULL);

--
-- PostgreSQL database dump complete
--

