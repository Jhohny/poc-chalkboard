# frozen_string_literal: true

# Local development seeds — anchors posts around San Francisco and
# sprinkles them across every radius tier (Very Close → Farther Out)
# so the adaptive-radius picker and distance labels can be exercised.
#
# Run with: bundle exec rails db:seed
# Safe to re-run: clears any previously seeded post (identified by
# the `seed_` prefix on its session_token_digest) before inserting.

ICONS      = %w[✦ ★ ☺ ☼ ✎ ♣ ♠ ♥ ♦ ☁ ☕ ☘ ☾ ♪].freeze
ADJECTIVES = %w[Quiet Local Neon Wandering Tin Soft Hidden Electric Paper Sidewalk North South].freeze
NOUNS      = %w[Sparrow Lantern Window Echo Marker Comet Kite River Brick Moth Signal Marble Haze].freeze

# Neighborhood anchors — (lat, lng) in decimal degrees, approximate
# distance from the dev anchor (SF, 37.7749 / -122.4194) in km.
NEIGHBORHOODS = [
  { name: 'Mission',        lat: 37.7599, lng: -122.4148, km: 1.7  },
  { name: 'Financial',      lat: 37.7946, lng: -122.3999, km: 2.7  },
  { name: 'Haight',         lat: 37.7692, lng: -122.4481, km: 2.6  },
  { name: 'Dogpatch',       lat: 37.7580, lng: -122.3874, km: 3.3  },
  { name: 'Sunset',         lat: 37.7546, lng: -122.4930, km: 6.4  },
  { name: 'Richmond',       lat: 37.7806, lng: -122.4644, km: 4.0  },
  { name: 'Presidio',       lat: 37.7989, lng: -122.4662, km: 4.8  },
  { name: 'Daly City',      lat: 37.6879, lng: -122.4702, km: 10.3 },
  { name: 'Oakland',        lat: 37.8044, lng: -122.2712, km: 13.3 },
  { name: 'Sausalito',      lat: 37.8591, lng: -122.4853, km: 11.9 },
  { name: 'Berkeley',       lat: 37.8715, lng: -122.2730, km: 17.0 },
  { name: 'South SF',       lat: 37.6547, lng: -122.4077, km: 13.4 },
  { name: 'San Mateo',      lat: 37.5630, lng: -122.3255, km: 24.8 },
  { name: 'Palo Alto',      lat: 37.4419, lng: -122.1430, km: 45.3 }
].freeze

BODIES_EN = [
  'fog rolled in early today',
  'the 38 was actually on time',
  'someone left flowers on my stoop',
  'pigeons won again',
  'smells like rain finally',
  'nobody talks on BART',
  'lost my umbrella twice this week',
  'the hills are brutal, worth it',
  'saw a coyote near the park',
  'mission sunset is unreal',
  'just moved here, send help',
  'the city smells different at 2am',
  'overheard someone explain NFTs to their grandma at the farmers market',
  "third coffee of the day and I still cannot figure out what I'm doing here",
  "the mural on Valencia got painted over and I'm still not over it",
  "there's a guy who plays cello outside Dolores every Saturday, legend",
  'someone left a perfectly good chair outside, I took it, no regrets',
  'the sunset from twin peaks tonight was worth every step of the hike',
  'fog is back and honestly I needed the reminder that summer is fake here',
  'finally got into that ramen spot with the hour-long wait, worth it',
  'the library on civic center is underrated, been hiding there all week',
  "someone spray-painted 'stay weird' on the wall they're about to tear down",
  'every neighborhood feels like its own city and I love that'
].freeze

BODIES_ES = [
  'huele a lluvia esta noche',
  'alguien dejó flores en el banco otra vez',
  'el café aquí es una religión',
  'perdí el bus, otra vez',
  'se escucha una trompeta cerca',
  'el gato del vecino vino a visitarme',
  'hoy la ciudad está callada y lo agradezco',
  'encontré una librería escondida entre dos bares',
  'los atardeceres aquí son distintos cada día',
  'alguien está practicando piano a dos calles',
  'caminé sin rumbo y encontré una panadería nueva',
  'me encantan las pequeñas cosas que nadie nota'
].freeze

BODIES = (BODIES_EN + BODIES_ES).freeze

# Wipe previously seeded rows so re-runs stay clean
Post.where("session_token_digest LIKE 'seed_%'").delete_all

now   = Time.current
posts = []

# ~3 posts per neighborhood — gives good density in close tiers
# and still lets distant neighborhoods show up under the widener.
NEIGHBORHOODS.each_with_index do |hood, hood_idx|
  3.times do |j|
    body = BODIES.sample

    # A small jitter (~100 m) so same-neighborhood posts don't colocate.
    lat = hood[:lat] + rand(-0.001..0.001)
    lng = hood[:lng] + rand(-0.001..0.001)

    posted_at  = now - rand(5..(47 * 60)).minutes
    expires_at = posted_at + Post::LIFETIME

    size = if body.length <= 32 then 'small'
    elsif body.length <= 80 then 'medium'
    else 'large'
    end

    posts << {
      pseudonym: "#{ADJECTIVES.sample} #{NOUNS.sample}",
      icon: ICONS.sample,
      body: body,
      latitude: lat.round(6),
      longitude: lng.round(6),
      rotation: rand(-4..4),
      color_variant: Post::COLOR_VARIANTS.sample,
      size_variant: size,
      posted_at: posted_at,
      expires_at: expires_at,
      session_token_digest: "seed_#{hood_idx}_#{j}_#{SecureRandom.hex(6)}",
      created_at: posted_at,
      updated_at: posted_at
    }
  end
end

Post.insert_all!(posts)

puts "Seeded #{posts.size} posts across #{NEIGHBORHOODS.size} neighborhoods " \
     '(anchor: San Francisco 37.7749, -122.4194)'
