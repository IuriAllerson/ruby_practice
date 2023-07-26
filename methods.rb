def get_teacher(id, client)
  f = "select firstname, middlename, lastname, birthdate from teachers_yourname where ID = #{id}"
  results = client.query(f).to_a
  if results.count.zero?
    puts "Teacher with ID #{id} was not found."
  else
    puts "Teacher #{results[0]['firstname']} #{results[0]['middlename']} #{results[0]['lastname']} was born on #{(results[0]['birthdate']).strftime("%d %b %Y (%A)")}"
  end
end