
def get_teacher(id, client)
  f = "SELECT first_name, middle_name, last_name, birth_date FROM teachers_iuri WHERE id = #{id}"
  results = client.query(f).to_a
  if results.count.zero?
    puts "Teacher with ID #{id} was not found."
  else
    puts "Teacher #{results[0]['first_name']} #{results[0]['middle_name']} #{results[0]['last_name']} was born on #{(results[0]['birth_date']).strftime("%d %b %Y (%A)")}"
  end
end

#1

def get_subject_teachers(subject_id, client)
  q = "SELECT s.name, t.first_name, t.middle_name, t.last_name FROM subjects_iuri AS s
  JOIN teachers_iuri AS t
  ON s.id = t.subject_id WHERE s.id = #{subject_id}"

  results = client.query(q).to_a

  if results.count.zero?
    puts "No one teaches the subject with ID #{subject_id}."
  else

    string = "Subject: #{results[0]['name']}\nTeachers:\n"

    results.each do |row|
      string += "#{row['first_name']} #{row['middle_name']} #{row['last_name']}\n"
    end

    puts string

  end
end

#2

def get_class_subjects(class_name, client)
  q = "SELECT DISTINCT s.name AS subject_name, t.first_name, t.middle_name, t.last_name
  FROM classes_iuri AS c
  JOIN teachers_classes_iuri AS tc
    ON tc.class_id = c.id
  JOIN teachers_iuri AS t
    ON t.id = tc.teacher_id
  JOIN subjects_iuri AS s
    ON s.id = t.subject_id WHERE c.name = \"#{class_name}\""

  results = client.query(q).to_a

  if results.count.zero?
    puts "There is no teacher teaching #{subject_name}."
  else
    string = ""

    results.each do |row|
      string += "#{row['subject_name']} (#{row['first_name']} #{row['middle_name']} #{row['last_name']})\n"
    end

    puts string
  end
end
#3

def get_teachers_list_by_letter(letter, client)
  q = "SELECT first_name, middle_name, last_name, s.name AS subject_name FROM classes_iuri AS c
  JOIN teachers_classes_iuri AS tc
    ON tc.class_id = c.id
  JOIN teachers_iuri AS t
    ON t.id = tc.teacher_id
  JOIN subjects_iuri AS s
    ON s.id = t.subject_id
  WHERE first_name LIKE '%#{letter}%' OR last_name LIKE '%#{letter}%'"

  results = client.query(q).to_a

  if results.count.zero?
    puts "There are no teachers whose first name or last name contains the letter \"#{letter}\""
  else

    string = "Subject: #{results[0]['name']}\nTeachers:\n"

    results.each do |row|
      string += "#{row['first_name']} #{row['middle_name']} #{row['last_name']}\n"
    end

    puts string

  end
end

#4

def set_md5(client)
  q = "SELECT * FROM teachers_iuri;"

  results = client.query(q).to_a

  results.each do |row|
    digested = Digest::MD5.hexdigest "#{row['middle_name']} #{row['middle_name']} #{row['last_name']} #{row['birth_date']} #{row['subject_id']} #{row['current_age']}"

    puts digested

    u = "UPDATE teachers_iuri SET md5 = '#{digested}' WHERE id = #{row['id']};"

    client.query(u)
  end
end

#5

def get_class_info(class_id, client)
  involved_teachers = "SELECT c.name, t.first_name, t.last_name
  FROM teachers_classes_iuri AS tc
    JOIN classes_iuri AS c
    ON tc.class_id = c.id
    JOIN teachers_iuri AS t
    ON tc.teacher_id = t.id
    WHERE c.id = #{class_id};"

  responsible_teacher = "SELECT c.name, t.first_name, t.last_name
  FROM classes_iuri AS c
    JOIN teachers_iuri AS t
    ON c.responsible_teacher_id = t.id
  WHERE c.id = #{class_id};"

  results_involved = client.query(involved_teachers).to_a
  results_responsible = client.query(responsible_teacher).to_a

  if results_involved.count.zero? or results_responsible.count.zero?
    puts "There are no involved or responsible teachers in class with id #{class_id}"
  else
    string = ""

    results_responsible.each do |row|
      string += "Class name: #{row['name']}\nResponsible teacher: #{row['first_name']} #{row['last_name']}\n"
    end

    results_involved.each do |row|
      string += "Involved teachers: #{row['first_name']} #{row['last_name']}"
    end

    puts string
  end
end

#6

def get_teachers_by_year(year, client)
  q = "SELECT first_name name FROM teachers_iuri
  WHERE YEAR(birth_date) = #{year}"

  results = client.query(q).to_a

  if results.count.zero?
    puts "There are no teachers born in #{year}"
  else
    string = "Teachers born in #{year}:"

    results.each do |row|
      string += " #{row['name']},"
    end

    puts string.gsub(/,$/, '.')
  end
end


def random_date(begin_date, end_date)
  begin_date = Date.parse(begin_date)
  end_date = Date.parse(end_date)

  random_date = rand(begin_date..end_date)

  random_date
end

def random_last_names(n, client)
  q = <<~SQL
    SELECT * FROM last_names
  SQL

  results = client.query(q).to_a

  results.map { |row| row['last_name'] }
end

def random_first_names(n, client)
  q = <<~SQL
    SELECT names FROM female_names
    UNION
    SELECT FirstName FROM male_names
  SQL

  results = client.query(q).to_a

  results.map { |row| row['names'] }
end

def random_people(n, client)
create_table  = <<~SQL
    CREATE TABLE IF NOT EXISTS random_people_iuri (
      id BIGINT(20) PRIMARY KEY AUTO_INCREMENT,
      first_name VARCHAR(30),
      last_name VARCHAR(30),
      birth_date DATE
    );
  SQL

  client.query(create_table)

  first_names = random_first_names(n, client)
  last_names = random_last_names(n, client)
  birth_dates = []

  n.times do
    birth_dates << random_date("1923-01-01", "2023-01-01").to_s
  end

  people = first_names.zip(last_names).zip(birth_dates).map(&:flatten)

  people.each_slice(10000) do |group|
    insert = "INSERT INTO random_people_iuri (first_name, last_name, birth_date) VALUES "
    group.each do |row|
      insert += "(\"#{row[0]}\", \"#{row[1]}\", \"#{row[2]}\"),"
    end
    client.query(insert.chop!)
  end
end
