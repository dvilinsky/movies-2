class Movie
  def initialize(user_id, movie_id, rating)
    @user_ids = [user_id] #all of the users who have rated this movie
    @movie_id = movie_id
    @ratings = [rating] #all of the ratings that this movie has been given
  end

  attr_accessor :user_ids, :movie_id, :ratings

  def add_rating(rating)
    @ratings.push(rating)
  end

  def add_user(user_id)
    @user_ids.push(user_id)
  end
end

class User
  def initialize(rating, movie, user_id)
    @ratings = {movie => rating} #mapping of all the movies user has rated to what said rating is
    @user_id = user_id
  end

  def add_rating(rating, movie)
    @ratings[movie] = rating
  end

  #returns the rating this user gave to a movice
  #parameter: movie id
  def get_rating(movie)
    return @ratings[movie]
  end

  attr_accessor :ratings, :user_id
end

class MovieData

  #makes two empty lists: one of movie objects, another of user objects
  def initialize()
    @movies = []
    @users = []
  end

  attr_accessor :movies, :users

  #reads in the u.data file and stores each movie into an array of movie objects
  #it also adds the users into the user array
  #paramter: a string f which is the name of the file to read in
  def load_data(f)
    data = open(f, "r")
    data.each_line do |line|
      data_array = line.split("\t")
      movie_id = data_array[1].to_i
      user_id = data_array[0].to_i
      rating = data_array[2].to_i
      if @movies[movie_id] == nil
        @movies[movie_id] = Movie.new(user_id, movie_id, rating)
      else
        @movies[movie_id].add_rating(rating)
        @movies[movie_id].add_user(user_id)
      end
      if @users[user_id] == nil
        @users[user_id] = User.new(rating, movie_id, user_id)
      else
        @users[user_id].add_rating(rating, movie_id)
      end
    end
  end

  #Here I define popularity as the sum of all the ratings, plus or
  #minus a factor that depends on how many of the ratings are 1 or 2
  #versus 4 or 5.  This is to avoid the case where a movie with ratings [1, 1, 1, 1, 1]
  #is as popular as a movie with rating [5]. The 25 is a magic number.
  #paramter: A movie id (integer)
  def popularity(movie_id)
    movie_ratings = @movies[movie_id].ratings
    percentages = {1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 =>0}
    sum_of_ratings = 0
    movie_ratings.each do |rating|
      sum_of_rataings += rating
      percentages[rating] += 1
    end
    percentages.each do |rating, amount|
      percentages[rating] = amount/movie_ratings.length.to_f
    end
    if percentages[1] + percentages[2] > percentages[4] + percentages[5]
      sum -= (25 * (percentages[1] + percentages[2]))
    else
      sum += (25 * (percentages[4] + percentages[5]))
    end
    return sum
  end

  #calls self.popularity on all the movies in the array, then sorts in descending order
  #Unfortunately if n is the number of movies, and r is the number of ratings that
  #movie has, the running time is O(n*r).
  def popularity_list
    pop_list = []
    @movies.each do |m|
      if m.nil?
        next
      else
        pop_list.push(popularity(m.movie_id))
      end
    end
    return pop_list.sort_by! {|n| 0 - n}
  end

  #My similarity method looks at only movies that both users have rated
  #This method disobeys the instructions, because higher numbers indicate that
  #two users are less similar.
  #parameters: two user id's (both ints)
  def similarity(user1, user2)
    u1 = @users[user1].ratings #u1's hash of movie id's => ratings
    u2 = @users[user2].ratings #u2's hash of movie id's => ratings
    intersection = u1.keys & u2.keys #movies both users have rated
    if intersection.length == 0
      return 200000000 #some really big number - if they have no movies in common, not at all similar
    end
    sim_factor = 0 #more of a difference factor than a similarity factor...
    intersection.each do |movie|
      sim_factor += (u1[movie] - u2[movie]).abs
    end
    return sim_factor
  end

  #creates and returns a hash mapping a similarity ranking to user
  #for all the users in the data set.
  #parameter: a user_id
  def most_similar(user_id)
    #Hash mapping a user to a similarity ranking
    similarity_hash = {@users[1].user_id => similarity(@users[1].user_id, user_id)}
    @users.each do |u|
      if u.nil? || u.user_id == user_id #don't want to map user to itself
        next
      else
        similarity_hash[u.user_id] = similarity(u.user_id, user_id)
      end
    end
    return similarity_hash.sort_by { |key, value| value}.to_h
  end
end

def get_last_ten(md)
  h = md.most_similar(1)
  reverse = Hash[h.to_a.reverse]
  return reverse.first(10).reverse
end
