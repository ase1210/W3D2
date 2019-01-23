require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end

class ModelBase
  def self.find_by_id(id)
    table_name = self.to_s.downcase + 's'
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    data.map { |datum| self.new(datum) }
  end
end

class Question < ModelBase

  # def self.find_by_id(id)
  #   data = QuestionsDatabase.instance.execute(<<-SQL, id)
  #     SELECT *
  #     FROM questions
  #     WHERE id = ?
  #   SQL
  #   data.map { |datum| Question.new(datum) }
  # end

  def self.find_by_author_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM questions
      WHERE user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  attr_accessor :title, :body, :user_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def author
    User.find_by_id(user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end
  
  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id, @id)
        UPDATE
          questions
        SET
          title = ?, body = ?, user_id = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, title, body, user_id)
        INSERT INTO
          questions (title, body, user_id)
        VALUES
          (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class User

  def self.find_by_name(fname, lname)
    data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT *
      FROM users
      WHERE fname = ? AND lname = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM users
      WHERE id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  attr_accessor :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT (COUNT(question_likes.user_id) / CAST(COUNT(DISTINCT(questions.id)) AS FLOAT)) AS avg_likes
      FROM questions
      LEFT JOIN question_likes ON questions.id = question_likes.question_id
      WHERE questions.user_id = ?
    SQL
    data[0]['avg_likes']
  end
  
  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, fname, lname, @id)
        UPDATE 
          users
        SET
          fname = ?, lname = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        INSERT INTO 
          users (fname, lname) 
        VALUES
          (?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class QuestionFollow

  def self.followers_for_question_id(question_id)
    user_ids = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT user_id
      FROM question_follows
      WHERE question_id = ?
    SQL
    user_ids.map { |user_id| User.find_by_id(user_id.values[0]) }.flatten
  end

  def self.followed_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT DISTINCT questions.id, questions.title, questions.body, questions.user_id
      FROM question_follows
      JOIN questions ON questions.user_id = question_follows.user_id 
      WHERE questions.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end
  
  def self.most_followed_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT DISTINCT questions.id, questions.title, questions.body, questions.user_id
      FROM question_follows
      JOIN questions ON questions.id = question_follows.question_id 
      GROUP BY question_follows.question_id
      ORDER BY SUM(question_follows.user_id) DESC
      LIMIT ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  attr_accessor :question_id, :user_id

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
  
end

class Reply

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT *
      FROM replys
      WHERE id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_parent_id(parent_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, parent_id)
      SELECT *
      FROM replys
      WHERE parent_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM replys
      WHERE user_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM replys
      WHERE question_id = ?
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  attr_accessor :question_id, :user_id, :body, :parent_id

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
  end
  
  def author
    User.find_by_id(user_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_id)
  end

  def child_replies
    Reply.find_by_parent_id(@id)
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, body, question_id, parent_id, user_id, @id)
        UPDATE
          replies
        SET
          body = ?, question_id = ?, parent_id = ?, user_id = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, body, question_id, parent_id, user_id)
        INSERT INTO
          replies (body, question_id, parent_id, user_id)
        VALUES
          (?, ?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end
end

class QuestionLike

  def self.likers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT users.id, users.fname, users.lname
      FROM question_likes
      JOIN users ON question_likes.user_id = users.id
      WHERE question_id = ?
    SQL
    data.map { |datum| User.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT COUNT(user_id) AS count
      FROM question_likes
      WHERE question_id = ?
      GROUP BY question_id
    SQL
    return 0 if data.empty?
    data[0]['count']
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT DISTINCT questions.id, questions.title, questions.body, questions.user_id
      FROM question_likes
      JOIN questions ON question_likes.question_id = questions.id
      WHERE question_likes.user_id = ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT DISTINCT questions.id, questions.title, questions.body, questions.user_id
      FROM question_likes
      JOIN questions ON questions.id = question_likes.question_id 
      GROUP BY question_likes.question_id
      ORDER BY SUM(question_likes.user_id) DESC
      LIMIT ?
    SQL
    data.map { |datum| Question.new(datum) }
  end

  attr_accessor :question_id, :user_id

  def initialize(options)
    @question_id = options['question_id']
    @user_id = options['user_id']
  end
  
end
