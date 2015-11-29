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
#   bag and tag|bagntag|bag n tag - Calculates the time until Bag and Tag day.
#   kick off|kickoff - Calculates the time until Kick Off day.
#
# Author:
#   Arthur Allshire
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->

  robot.hear /bag and tag|bagntag|bag n tag/i, (msg) ->
    message = datediff(new Date(2016, 1, 23, 23, 59, 59), "Bag and Tag")
    if token = null
      message = stripslack(message)
    msg.send(message)

  robot.hear /kickoff|kick off/i, (msg) ->
    message = datediff(new Date(2016, 0, 10, 8, 0, 0), "Kick Off")
    if token = null
      message = stripslack(message)
    msg.send(message)


  datediff = (eventDate, eventName) ->
    today = new Date()
    MINUTE = 1000*60
    HOUR = MINUTE*60
    DAY = HOUR*24
    days_to_go = Math.floor( (eventDate.getTime()-today.getTime())/DAY)
    hours_to_go = Math.floor( (eventDate.getTime()-today.getTime() - days_to_go*DAY)/HOUR)
    mins_to_go = Math.floor( (eventDate.getTime()-today.getTime() - days_to_go*DAY - hours_to_go*HOUR)/MINUTE)
    if days_to_go < 0
      message = eventName[0].toUpperCase() + eventName[1..-1] + " was " + (-days_to_go) + " days ago."
    else
      message = "There are " + days_to_go + " days, " + hours_to_go + " hours and " + mins_to_go + " minutes until " + eventName + "."
    return message


  stripslack = (toStrip) ->
    toStrip = toStrip.replace(new RegExp('\\*', 'g'), '')
    toStrip = toStrip.replace(new RegExp('\\_', 'g'), '')
    return toStrip
