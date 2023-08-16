require 'mysql2'
require 'dotenv/load'
require 'digest'


client = Mysql2::Client.new(host: "db09.blockshopper.com", username: ENV['DB09_LGN'], password: ENV['DB09_PWD'], database: "applicant_tests")

def escape(str)
  str = str.to_s
  return str if str == ''
  return if str == ''
  str.gsub(/\\/, '\&\&').gsub(/'/, "''")
end

def clean_names(client)
  begin
    create_table = <<~SQL
      CREATE TABLE hle_dev_test_iuri
      AS SELECT * FROM hle_dev_test_candidates;
    SQL

    client.query(create_table)

    add_columns = <<~SQL
      ALTER TABLE hle_dev_test_iuri
        ADD clean_name VARCHAR(255),
        ADD sentence VARCHAR(255),
      ADD CONSTRAINT unique_name UNIQUE (candidate_office_name);
    SQL

    client.query(add_columns)

  rescue Mysql2::Error
    insert_data = <<~SQL
      INSERT IGNORE INTO hle_dev_test_iuri(name)
      SELECT DISTINCT name FROM hle_dev_test_candidates;
    SQL
  end

  retrieve_data = <<~SQL
    SELECT * FROM hle_dev_test_iuri WHERE clean_name IS NULL;
  SQL

  names = client.query(retrieve_data).to_a

  names.each do |name|
    name = row['candidate_office_name']
    up_candidate = name.downcase
                       .gsub(/\bCounty Clerk\/Recorder\/DeKalb County\b/i, "DeKalb County clerk and recorder")
                       .gsub(/\bTwp\b/i, "Township")
                       .gsub(/\bHwy\b|\bhighway\b/i, "Highway")
                       .gsub(/\.$/, '')
                       .gsub(/(.+)\/(.+)/) { |match| "#{$2.capitalize} #{$1.capitalize}" }
                     .gsub(/\//) { |match| '' }
                     .gsub(/(\w+),\s*(.*)/){ "#{$1} (#{$2.split.map(&:capitalize).join(' ')})" }
                     .gsub(/\,/, '')
                     .gsub(/\b(\w+)\b(?=.*\b\1\b)/i, '')
                     .strip.gsub(/\s+/, ' ')

    end
                   .gsub(/\bTwp\b/i, 'Township')
                   .gsub(/\bHwy\b/i, 'Highway')
                   .gsub(/,\s*(.+)/, ' (\1)')
                   .gsub(/\b(\w+)\b\s+\1\b/i, '\1')
                   .strip

    insert_clean_name = <<~SQL
      UPDATE hle_dev_test_iuri
      SET clean_name = '#{escape(clean_name)}'
      WHERE candidate_office_name = '#{escape(name['candidate_office_name'])}';
    SQL

    client.query(insert_clean_name)

    insert_sentence = <<~SQL
      UPDATE hle_dev_test_iuri
      SET sentence = 'The candidate is running for the #{escape(clean_name)} office.'
      WHERE candidate_office_name = '#{escape(name['candidate_office_name'])}';
    SQL

    client.query(insert_sentence)
  end
end

clean_names(client)
