# Local development seeds — populates the San Francisco wall with 120+ notes.
# Run with: bundle exec rails db:seed
# Safe to re-run: clears existing seed posts first (identified by seed digest prefix).

SEED_CITY_SLUG = ENV.fetch("LOCAL_CITY_FALLBACK", "San Francisco").parameterize.freeze
SEED_CITY_NAME = ENV.fetch("LOCAL_CITY_FALLBACK", "San Francisco").freeze

ICONS      = %w[✦ ★ ☺ ☼ ✎ ♣ ♠ ♥ ♦ ☁ ☕ ☘ ☾ ♪].freeze
ADJECTIVES = %w[Quiet Local Neon Wandering Tin Soft Hidden Electric Paper Sidewalk North South].freeze
NOUNS      = %w[Sparrow Lantern Window Echo Marker Comet Kite River Brick Moth Signal Marble Haze].freeze

BODIES = [
  # short (≤32 chars → small)
  "fog rolled in early today",
  "the 38 was actually on time",
  "someone left flowers on my stoop",
  "coffee shop is full again",
  "quiet morning, rare thing",
  "pigeons won again",
  "smells like rain finally",
  "the light here is different",
  "nobody talks on bart",
  "lost my umbrella twice this week",
  "sourdough everywhere, I love it",
  "construction on 24th, always",
  "good bagel energy today",
  "the hills are brutal, worth it",
  "saw a coyote near the park",
  "mission sunset is unreal",
  "cold even in july, still love it",
  "just moved here, send help",
  "tech layoffs hit my block hard",
  "the city smells different at 2am",
  # medium (33–80 chars → medium)
  "bus driver waved at a dog on the sidewalk and honestly that saved my day",
  "overheard someone explain nfts to their grandma at the farmers market",
  "third coffee of the day and I still cannot figure out what I'm doing here",
  "the mural on Valencia got painted over and I'm still not over it",
  "there's a guy who plays cello outside Dolores every Saturday, legend",
  "rent went up again. roommate meeting tonight. vibes are not great",
  "someone left a perfectly good chair outside, I took it, no regrets",
  "the sunset from twin peaks tonight was worth every step of the hike",
  "my neighbor started a sourdough club, I've been roped in, send help",
  "fog is back and honestly I needed the reminder that summer is fake here",
  "the burritos on mission are a religion and I am a believer",
  "accidentally walked into a film shoot on my way to the laundromat",
  "every coffee shop now has a two hour limit, feels like we lost something",
  "golden gate was completely invisible today, just vibes and gray",
  "finally got into that ramen spot with the hour-long wait, worth it",
  "the library on civic center is underrated, been hiding there all week",
  "ran into my old roommate at the same spot we met three years ago wild",
  "transit is broken again but a stranger shared their umbrella so even",
  "the dog count at Alamo Square today was genuinely impressive, maybe 40",
  "someone spray painted 'stay weird' on the wall they're about to tear down",
  "woke up at 6 to see the bay and it was completely worth it, do it once",
  "the coffee here costs more than my first paycheck did but it is perfect",
  # long (81–120 chars → large)
  "I've lived here for five years and the fog still makes me stop and stare every single time it rolls in over Twin Peaks",
  "the diversity on a single muni car is something I think about a lot — every language, every age, everyone just going somewhere",
  "this city is expensive and chaotic and sometimes completely broken but it's mine now and I don't want to be anywhere else honestly",
  "wrote half a novel in that Haight café that closed last year and I keep walking by the empty storefront like a ghost, it's embarrassing",
  "someone in my building has been leaving little notes in the elevator for six months, tiny jokes, tiny poems, I hope they never stop",
  "the homelessness here is heartbreaking and I don't have answers but I think pretending not to see people is making all of us worse",
  "there are microclimates within two blocks of my apartment and I find it genuinely delightful that the weather has opinions about streets",
  "my landlord raised rent and my neighbor threw a block party the same weekend and both things feel equally San Francisco to me somehow",
  "you can tell a lot about a city by its 2am crowd and this city's 2am crowd is tired and hungry and kind and a little bit lost, perfect",
  "the bay at low tide on a tuesday when no one else is around is the most honest version of this city I've ever seen and I keep going back",
  "been here three months and still can't tell if I'm a local or just a tourist with an apartment, probably both, probably that's the point",
  "every neighborhood feels like its own city and moving between them in one afternoon is one of the small free things I love about living here",
].freeze

# Remove any previously seeded posts so re-running stays clean
Post.where("session_token_digest LIKE 'seed_%'").delete_all

now   = Time.current
posts = []

1030.times do |i|
  pseudonym = "#{ADJECTIVES.sample} #{NOUNS.sample}"
  icon      = ICONS.sample
  body      = BODIES[i % BODIES.length]

  # Spread across the last 47 h so notes span the full opacity range
  posted_at  = now - rand(0..(47 * 3600)).seconds
  expires_at = posted_at + Post::LIFETIME

  rotation     = rand(-4..4)
  x_position   = rand(-22..22)
  y_position   = rand(0..26)
  color_variant = Post::COLOR_VARIANTS.sample
  size_variant  = if body.length <= 32 then "small"
                  elsif body.length <= 80 then "medium"
                  else "large"
                  end

  posts << {
    city_slug:            SEED_CITY_SLUG,
    city_name:            SEED_CITY_NAME,
    pseudonym:            pseudonym,
    icon:                 icon,
    body:                 body,
    posted_at:            posted_at,
    expires_at:           expires_at,
    session_token_digest: "seed_#{i}_#{SecureRandom.hex(8)}",
    rotation:             rotation,
    x_position:           x_position,
    y_position:           y_position,
    color_variant:        color_variant,
    size_variant:         size_variant,
    created_at:           posted_at,
    updated_at:           posted_at
  }
end

Post.insert_all!(posts)
puts "Seeded #{posts.size} posts for #{SEED_CITY_NAME} (#{SEED_CITY_SLUG})"
