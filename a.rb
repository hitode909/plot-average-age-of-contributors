Bundler.require
require 'date'

class CommitAt
  def commit_at(date)
    @dates = [] unless @dates
    @dates << date
    @since = date unless @since
    @since = date if date < @since
    @till = date unless @till
    @till = date if date > @till
  end

  def since
    @since
  end

  def till
    @till
  end

  def commit_count
    @dates.length
  end

  def age
    till - since
  end

  def age_at(date)
    date - since.to_date
  end

  def active_at? date
    @dates.find{|d| d.year == date.year && d.month == date.month}
  end
end

class Project < CommitAt
  def initialize(workspace)
    @workspace = workspace
    @contributors = {}
  end

  def analyze!
    git = Git.open(@workspace)
    git.log(999999999).each{|log|
      next unless log.date
      self.commit_at(log.date)
      self.contributor(log.author.name).commit_at log.date
    }
  end

  def contributors
    @contributors.values.sort_by(&:age).reverse
  end

  def contributor(name)
    unless @contributors[name]
      @contributors[name] = Contributor.new(name)
    end
    @contributors[name]
  end
end

class Contributor < CommitAt
  def initialize(name)
    @name = name
  end
  def name
    @name
  end
end

require 'pp'
WORKING_DIR = ARGV.first
project = Project.new(WORKING_DIR)
project.analyze!

puts ['date', 'average age'].join("\t")
(project.since.to_date..project.till.to_date).select{|date| date.day == 1}.each{|date|
  active_contributors = project.contributors.select{|c| c.active_at?(date)}
  average = active_contributors.length > 0 ? active_contributors.map{|c| c.age_at(date)}.reduce(0){|a,b| a + b } / active_contributors.length.to_f / (date - project.since.to_date) * 100 : 0
  puts [date, average, active_contributors.sort_by{|c| c.age}.reverse.map{|c| c.name}].flatten.join("\t")
}
