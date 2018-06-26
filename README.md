# Ruby Slackbot

Ruby Slack bot skeleton, meant for a Heroku deploy

## Installation

### Slack

* Log into [Slack](https://slack.com/?story=roiproofpoints&s=1)
* Configure Integrations > DIY Integrations & Customizations > Bots
  * ```Integration Settings API Token``` : {SLACK_BOT_TOKEN}

### Heroku

* Log into [Heroku](https://id.heroku.com/login)
* Application > Settings > Config Vars
  * Add ```SLACK_BOT_TOKEN``` with value {SLACK_BOT_TOKEN}
  * Add ```REDIS_URL``` with value {REDIS_URL}