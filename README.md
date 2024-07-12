# README

This is an archival copy of an old private repo. It includes most of a spin off project I'm working on called Oroshi. This won't work without significant fiddling, many files have been removed and it's not designed to be an open source project, it's just a record of some of the work i've done over the years.

# Explanation

Developed as "Funabiki Online" (at: https://funabiki.online), "seafood-ms" is a seafood business management system (hence the 'ms'). It started as just an accounting tool for the Funabiki family oyster business. You can learn more about the company at http://funabiki.info and order oysters from our site that I also designed that runs on Solidus at http://samuraioyster.com.

The tool quickly grew to make various tasks easier for office and floor staff. The Oroshi tool is designed to be spun off as an MRP (Material Requirements Planning and Order Management) Saas platform.

This is an edited branch of the private repository mainly provided for posterity, and because I'm pretty proud of it. It is a good exempliar of my coding progress and a useful resource for anyone looking for various implementation snippets or ideas for their own projects.

## The platform currently includes:

- Rails 7+ Frontend written with ERB, Bootstrap 5 and Hotwire/Turbo and Stimulus using only importmaps (nodejs/yarn more-or-less removed/unused)
- Product data input system, with an integrated overhead cost estimation tool based on associated Materials.
- Invoicing tool for generating purchase records and statistics for distribution to oyster farmers individually and through their union.
- Along with the above is a system for tracking raw materials (various types of oysters) from suppliers. This system includes a form which is editable in real-time by multiple users over websocekts using ActionCable and various Stimulus Controllers. This tool also includes a way to print reception confirmation documents which can be used as HACCP Critical Control Point verification records.
- A wholesale market daily accounting tool, including detailed statistics and data about sales, product and raw material volumes and profits.
- An e-commerce API integration tool (specific to our needs) for Rakuten (楽天) which tracks daily order and shipping data, including a printable daily shipping list.
- An automated order processing library for Rakuten, using their API.
- An integration tool (specific to our needs) for the Infomart (インフォマート) B2B restaurant supply system (uptakes via CSV as Infomart has no API), including a printable daily shipping list.
- Twp further ecommerce integration tools for our Solidus site using it's built in API and Yahoo!Shopping Japan, using it's API (requires a static API, which we acquire through QuotaGuard). All the ecommerce systems are united by a central ec product model to track inventory help with forcasting product flow.
- A Noshi (熨斗) generator which is integrated with Google Cloud (A noshi is a wrapper with a name on it used for traditional Japanese gifts). (This was moved to [it's own repo](https://github.com/cmbaldwin/noshi) and is hosted on the free tier at https://noshi.onrender.com/)
- A tool for creating (and scheduled daily) printable expiration cards of any type (in our case for raw shelled oysters).
- Simple infographics/charts for various statistics (tracks three years of data) using ChartKick (Chart.js).
- A simple reciept (領収証) generator for online customers.
- A async job system using SideKiq which sends messages so they can see the status of their request and access files when it's complete (when generating documents of various kinds or performing API updates, etc.)
- Tests written in Rails default test enviornment (capybara, selenium, ApplicationSystemTestCase) for all basic functionality.

## Current and future projects include:

- Right now wholesale orders are accepted by phone and recorded by pen. This means that there's data entry happening 3 times: when the order is placed it's written down, it's recorded in our seperate finance system for wholesale invoicing (we use MJS NX-Pro), and then recorded again in our own system which tracks inventory, overhead and estimates profit. The dream is to combine all these into one point. An order is input in the system, it can be seen by anyone in the factory and there is no further data entry across systems (it could be automatically populated to the MJS database).
- Right now there are two models with a big hash full of too much data and association. Those are OysterSupplies.data and Profit.data. I want to seperate Supplies into: Supplies, SupplyTypes, SupplyTypeVariations, ReceptionTimes, and Locations—right now all of these associations are hard coded into the dada hash of Supplies. Same for Profit.data. Seperating the Profit.data into WholesaleOrders -> WholesaleProducts -> FactoryProducts would be more efficent, expressive and versatile for future upgrades (like the one mentioned above).
- Continue adding more robust testing throughout. Continuing to stay in the habit of creating tests as functionality is added. I have limited experience with Rspec, and I'd like to work on it more, so perhaps convert the tests to Rspec.

## Specifications

- Ruby version

  - '3.3'

- Rails version

  - '7.1.2'

- System dependencies

  - Heroku
  - Rails/all
  - Hotwire/Turbo
  - Hotwire/Stimulus

- Configuration, Setup and Deployment
  - [Heroku-22 stack](https://devcenter.heroku.com/articles/getting-started-with-ruby)
  - -> Buildpack Setup (in order)
    - heroku/ruby
    - https://github.com/weibeld/heroku-buildpack-graphviz
    - heroku/metrics
    - https://github.com/buyersight/heroku-google-application-credentials-buildpack
  - This project currently uses these Heroku add-ons:
    - Heroku Postgres (database)
    - Heroku Scheduler (for automated tasks)
    - SendGrid (for user emails)
    - Heroku Redis (caching, app speed)
