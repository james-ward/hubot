# Description:
#   Time tracking to see who is working the hardest!
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot clock in - Clock in to track your robot working hours
#   hubot clock out - Finish working for the day
#   hubot tempus fugit - Display a leaderboard of working hours
#
# Author:
#   JRW
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->
  robot.respond /clock in/i, (res) ->
    res.reply clock_in(res.message.user.name)

  robot.respond /clock out/i, (res) ->
    res.reply clock_out(res.message.user.name)

  robot.respond /tempus fugit/i, (res) ->
    msg = "No leaderboard implemented yet!"
    if token = null
      msg = stripslack(msg)
    res.reply msg

  clock_in = (username) ->
    clocked_in = robot.brain.get('clocked_in') or []
    if username in clocked_in
      msg = "Already clocked in!"
    else
      clocked_in.push username
      today = new Date()
      robot.brain.set('clocked_in', clocked_in)
      time_cards = robot.brain.get("tempus_fugit") or {}
      user_time_cards = time_cards[username] or []
      user_time_cards.push today
      time_cards[username] = user_time_cards
      robot.brain.set("tempus_fugit", time_cards)
      msg = "Clocked in at " + today.getHours() + ":" + forceTwoDigits(today.getMinutes())
      msg += "\nYou have clocked up " + human_time(total_time(user_time_cards))
    if token = null
      msg = stripslack(msg)
    return msg

  clock_out = (username) ->
    clocked_in = robot.brain.get('clocked_in') or []
    if username not in clocked_in
      msg = "Already clocked out!"
    else
      clocked_in = clocked_in.filter (name) -> name isnt username
      today = new Date()
      robot.brain.set('clocked_in', clocked_in)
      time_cards = robot.brain.get("tempus_fugit") or {}
      user_time_cards = time_cards[username] or []
      user_time_cards.push today
      robot.brain.set("tempus_fugit", time_cards)
      msg = "Clocked out at " + today.getHours() + ":" + forceTwoDigits(today.getMinutes())
      msg += "\nYou have clocked up " + human_time(total_time(user_time_cards))
    if token = null
      msg = stripslack(msg)
    return msg

  forceTwoDigits = (val) ->
    if val < 10
      return "0#{val}"
    return val

  stripslack = (toStrip) ->
    toStrip = toStrip.replace(new RegExp('\\*', 'g'), '')
    toStrip = toStrip.replace(new RegExp('\\_', 'g'), '')
    return toStrip

  total_time = (time_cards) ->
    t = 0
    # Pair the entries
    for e, idx in time_cards by 2
      first = new Date(time_cards[idx])
      if idx + 1 == time_cards.length
        # Odd number of entries
        second = new Date()
      else
        second = new Date(time_cards[idx + 1])
      t = t + second.getTime() - first.getTime()
    return t / 1000.0

   human_time = (seconds) ->
     hours = Math.floor(seconds / 3600)
     minutes = Math.round( (seconds - 3600 * hours) / 60)
     if hours
       return hours + " hours, " + minutes + " minutes "
     else
       return minutes + " minutes"
