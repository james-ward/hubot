# Description:
#   Allows for the lookup of different events
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot team <team_number> - Looks up the specified team number and returns details.
#
# Author:
#   JRW
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->

  robot.hear /[Tt]eam (\d{1,4})(?!\S)/i, (msg) ->
    teamToSearch = msg.match[1]
    robot.logger.info teamToSearch
    robot.http('http://www.thebluealliance.com/api/v2/team/frc' + teamToSearch)
      .header('X-TBA-App-Id', 'frc4774:hubot:v0.1')
      .get() (err, res, body) ->
        data = JSON.parse body
        message = '*FRC Team ' + teamToSearch + ' - ' + data.nickname + '*\n'
        message += '*Location:* ' + data.location + '\n' if data.location
        message += '*Website:* ' + data.website + '\n' if data.website
        message += '*Rookie Year:* ' + data.rookie_year if data.rookie_year
        if token = null
          message = stripslack(message)
        msg.send(message)

  stripslack = (toStrip) ->
    toStrip = toStrip.replace(new RegExp('\\*', 'g'), '')
    toStrip = toStrip.replace(new RegExp('\\_', 'g'), '')
    return toStrip
