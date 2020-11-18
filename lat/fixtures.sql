INSERT INTO concepts (id, created_at, title, concept) VALUES (1, '2015-03-19', 'roses', 'roses are red');
INSERT INTO concepts (id, created_at, title, concept) VALUES (2, '2015-03-19', 'violets', 'violets are blue');
INSERT INTO concepts (id, created_at, title, concept) VALUES (3, '2015-03-19', 'sugar', 'sugar is sweet');
INSERT INTO concepts (id, created_at, title, concept) VALUES (4, '2015-04-06', 'tagless', 'has no tags');


INSERT INTO tags (id, tag) VALUES (1, 'flower');
INSERT INTO tags (id, tag) VALUES (2, 'color');
INSERT INTO tags (id, tag) VALUES (3, 'flavor');


INSERT INTO concepts_tags (concept_id, tag_id) VALUES (1, 1);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (2, 1);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (1, 2);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (2, 2);
INSERT INTO concepts_tags (concept_id, tag_id) VALUES (3, 3);


INSERT INTO urls (id, url, notes) VALUES (1, 'http://www.rosesarered.co.nz/', NULL);
INSERT INTO urls (id, url, notes) VALUES (2, 'http://en.wikipedia.org/wiki/Roses_are_red', NULL);
INSERT INTO urls (id, url, notes) VALUES (3, 'http://en.wikipedia.org/wiki/Violets_Are_Blue', 'many refs here');

INSERT INTO concepts_urls (concept_id, url_id) VALUES (1, 1);
INSERT INTO concepts_urls (concept_id, url_id) VALUES (1, 2);
INSERT INTO concepts_urls (concept_id, url_id) VALUES (2, 3);

INSERT INTO pairings (id, created_at, concept1_id, concept2_id, thoughts) VALUES (1, '2015-03-19', 1, 2, 'describing flowers');

