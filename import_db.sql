PRAGMA foreign_keys = ON;



CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replys (
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  question_id INTEGER NOT NULL,
  parent_id INTEGER,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (parent_id) REFERENCES replys(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE question_likes (
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ("Drew", "Engelstein"), ("Mike", "Madsen");

INSERT INTO
  questions (title, body, user_id)
VALUES
  ("Dogs??", "What are they all about?", (SELECT id FROM users WHERE fname = "Drew")),
  ("Tomorrow?", "How do I keep track of days?", (SELECT id FROM users WHERE fname = "Mike")),
  ("alexa", "alexa where am i", (SELECT id FROM users WHERE fname = "Drew"));

INSERT INTO
  question_follows (question_id, user_id)
VALUES
  (1, 2),
  (2, 1),
  (3, 1),
  (2, 2);


INSERT INTO
  replys (body, question_id, parent_id, user_id)
VALUES
  ("food.", 1, NULL, 2),
  ("doi...", 1, 1, 1),
  ("why did you ask??", 1, 2, 2),
  ("Cuddles!", 1, NULL, 2),
  ("yur fone", 2, NULL, 1),
  ("Look at a calender.", 2, NULL, 1);

INSERT INTO
  question_likes (question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (2, 2),
  (3, 2);
  
