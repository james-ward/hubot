# Description:
#  Allows for shots to be fired with a simple command
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot fireshots <number of shots> - Fires the specified number of shots
#
# Author:
#  Arthur Allshire
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->

  robot.respond /fireshots (.*)/i, (msg) ->
    shotstofire = msg.match[1]
    message = ""
    if shotstofire > 10
      shotstofire = 10
    for i in [0...shotstofire]
      message += "OH OH, SHOTS FIRED\n"
    if token = null
        message = stripslack(message)
    msg.send(message)

  stripslack = (toStrip) ->
    toStrip = toStrip.replace(new RegExp('\\*', 'g'), '')
    toStrip = toStrip.replace(new RegExp('\\_', 'g'), '')
    return toStrip
