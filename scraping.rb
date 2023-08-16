require 'open-uri'
require 'nokogiri'
require 'byebug'
require 'mysql2'
require 'dotenv/load'

 client = Mysql2::Client.new(host: "db09.blockshopper.com", username: ENV['DB09_LGN'], password: ENV['DB09_PWD'], database: "applicant_tests")

def create_table(client)
  begin
    create_table = <<~SQL
      CREATE TABLE scraping_iuri(
        country VARCHAR(255),
        population VARCHAR(150),
        percentage_of_world VARCHAR(50),
        date VARCHAR(50),
        source VARCHAR(150),
        UNIQUE KEY unique_country (country)
      );
    SQL

    client.query(create_table)

    doc = Nokogiri::HTML(URI.open('https://en.wikipedia.org/wiki/List_of_countries_and_dependencies_by_population'))

    doc.css('table.wikitable tr').each_with_index do |row, index|
      next if index == 0

      cells = row.css('th, td')
                 .map(&:text)
                 .map(&:strip)

      country = client.escape(cells[1].gsub(/[\u00A0\s]+/, ' ').strip)
      population = client.escape(cells[2])
      percentage_of_world = client.escape(cells[3])
      date = client.escape(cells[4])
      source = client.escape(cells[5].gsub(/\[\d+\]|\[\w+\]/, ''))

      insert_data = <<~SQL
        INSERT IGNORE INTO scraping_iuri (country, population, percentage_of_world, date, source) VALUES('#{country} ', '#{population}', '#{percentage_of_world}', '#{date}', '#{source}')
        SQL

      client.query(insert_data)
    end
  rescue Mysql2::Error
    puts 'Table already exists'
  end
end

create_table(client)