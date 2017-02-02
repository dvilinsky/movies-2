require "./movies1.rb"

class Bucket
  def initialize(predictions, reality)
    @predictions = predictions
    @reality = reality
  end

  attr_accessor :predictions, :reality
end

class Rating

  #parameter: path to a file from which we create the MovieData object
  def initialize(file_path)
    md = MovieData.new
    md.load_data(file_path)
    @the_data = md
  end

  attr_accessor :the_data

  #this method creates a hash of users most similar to "user_id" that is
  #sorted in descending order of similarity- first element is most similar, second
  #element is second most similar, etc. Then returns the rating of the first user in that
  #hash who has rated "movie_id". Problem: what if nobody in the similarit list has
  #rated "movie_id."
  #parameters: two integers, one a movie ID, the other a user ID
  def predict(user_id, movie_id)
    prediction = 0
    most_similar_users = @the_data.most_similar(user_id)
    #find first user who has rated movie_id
    most_similar_users.each do |u, ranking|
      #we want the first user in most_similar_users who rated movie_id
      if @the_data.users[u].ratings[movie_id] != nil
        prediction = @the_data.users[u].ratings[movie_id]
        break
      end
    end
    return prediction
  end

  def predict_all(user_id)
    predictions = []
    reality = @the_data.users[user_id].ratings.values
    movies = @the_data.users[user_id].ratings.keys
    movies.each do |m|
      predictions.push(predict(user_id, m))
    end
    b = Bucket.new(predictions, reality)
    return b
  end
end

class Validator

  #paramter = an instance of class Rating
  def initialize(rating)
    @the_rating = rating
  end

  def generate_all_predictions
    @buckets = [] #list of bucket objects
    data = @the_rating.the_data
    users = data.users
    users.each do |u|
      b = @the_rating.predict_all(u.user_id) unless u == nil
      @buckets.push(b)
    end
    puts "\n"
  end

  def get_errors
    @errors = [] #list of all the errors
    @total_predictions = 0
    @num_wrong = 0
    @buckets.each do |b|
      if b == nil
        next
      end
      @total_predictions += b.predictions.size
      b.predictions.each_with_index do |pred, index|
        error = (pred - b.reality[index]).abs
        if error != 0
          @num_wrong += 1
        end
        @errors.push(error)
      end
    end
    puts "errors.size is #{@errors.size}"
    puts "Total predictions is #{@total_predictions}"
    puts "Total wrong is #{@num_wrong}"
    puts "So, the percent I got wrong is #{@num_wrong/@total_predictions.to_f}"
    puts "\n"
  end

  #returns the mean of the error in predictions, where the error is
  # abs_value(prediction - reality)
  def mean
    get_errors
    sum = 0
    @errors.each {|e| sum += e}
    avg = sum / @total_predictions.to_f
    return avg
  end

  #computes and returns the standard deviation of the prediction error
  def std_dev
    avg = mean()
    sum_sqrd_diffs = 0
    @errors.each do |e|
      sum_sqrd_diffs += ((e - avg) ** 2)
    end
    return Math.sqrt(sum_sqrd_diffs/(@total_predictions.to_f - 1))
  end

  def std_err
    return std_dev/Math.sqrt(@total_predictions)
  end

  def report_stats
    puts "The average of the error in prediction is " + mean.to_s
    puts "The standard deviation of that is " + std_dev.to_s
    puts "The standard error is #{std_err()}"
  end
end

puts Time.now
r = Rating.new("ml-100k/u1.test")
v = Validator.new(r)
v.generate_all_predictions
v.report_stats
puts Time.now
