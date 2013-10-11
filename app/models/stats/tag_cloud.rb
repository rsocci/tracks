# tag cloud code inspired by this article
#  http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
class TagCloud
  attr_reader :user, :tags, :tags_min, :tags_divisor, :tags_for_cloud_90days, :tags_min_90days, :tags_divisor_90days
  def initialize(user, cut_off)
    @user = user
    @cut_off = cut_off
  end

  # TODO: parameterize limit
  def compute
    levels=10

    query = "SELECT tags.id, name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND taggings.taggable_id = todos.id"
    query << " AND todos.user_id="+user.id.to_s+" "
    query << " AND taggings.taggable_type='Todo' "
    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"
    @tags = Tag.find_by_sql(query).sort_by { |tag| tag.name.downcase }

    max, @tags_min = 0, 0
    @tags.each { |t|
      max = [t.count.to_i, max].max
      @tags_min = [t.count.to_i, @tags_min].min
    }

    @tags_divisor = ((max - @tags_min) / levels) + 1

    @tags_for_cloud_90days = Tag.find_by_sql(
      [sql_90days, user.id, @cut_off, @cut_off]
    ).sort_by { |tag| tag.name.downcase }

    max_90days, @tags_min_90days = 0, 0
    @tags_for_cloud_90days.each { |t|
      max_90days = [t.count.to_i, max_90days].max
      @tags_min_90days = [t.count.to_i, @tags_min_90days].min
    }

    @tags_divisor_90days = ((max_90days - @tags_min_90days) / levels) + 1
  end

  private

  def sql_90days
    query = "SELECT tags.id, tags.name AS name, count(*) AS count"
    query << " FROM taggings, tags, todos"
    query << " WHERE tags.id = tag_id"
    query << " AND todos.user_id=? "
    query << " AND taggings.taggable_type='Todo' "
    query << " AND taggings.taggable_id=todos.id "
    query << " AND (todos.created_at > ? OR "
    query << "      todos.completed_at > ?) "
    query << " GROUP BY tags.id, tags.name"
    query << " ORDER BY count DESC, name"
    query << " LIMIT 100"
  end
end
