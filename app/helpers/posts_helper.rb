# frozen_string_literal: true

module PostsHelper
  def distance_band_label(distance_km)
    case distance_km
    when nil, 0..0.75 then t('distance.very_close')
    when 0.75..2      then t('distance.close')
    when 2..8         then t('distance.near')
    when 8..20        then t('distance.around')
    else                   t('distance.far')
    end
  end

  def time_ago_phrase(post)
    t('distance.time_ago', time: time_ago_in_words(post.posted_at))
  end
end
