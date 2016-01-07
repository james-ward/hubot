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
#   hubot open for business - Turn on time tracking. Must be in #management
#   hubot finished for the day - Clock everyone out and turn off time tracking. Must be in #management
#
# Author:
#   JRW
token = process.env.HUBOT_SLACK_TOKEN

module.exports = (robot) ->
  robot.respond /clock in/i, (res) ->
    robot.emit 'clock_in', res.message.user.name, res.message.room
    res.send human_leaderboard(leaderboard(robot.brain.get('tempus_fugit')))

  robot.respond /clock out/i, (res) ->
    robot.emit 'clock_out', res.message.user.name, res.message.room

  robot.respond /tempus fugit/i, (res) ->
    res.send human_leaderboard(leaderboard(robot.brain.get('tempus_fugit')))

  robot.router.get '/dropbot/tempus-fugit/qr/:username', (req, res) ->
    username = req.params.username
    clocked_in = robot.brain.get('clocked_in') or []
    if username in clocked_in
      robot.emit 'clock_out', username, "tempus-fugit"
    else
      robot.emit 'clock_in', username, "tempus-fugit"
    json_leaderboard(res)

  robot.router.get '/dropbot/tempus-fugit/leaderboard', (req, res) ->
    json_leaderboard(res)

  json_leaderboard = (res) ->
    res.writeHead 200, {'Content-Type': 'application/json'}
    real_names = {}
    lb = leaderboard(robot.brain.get('tempus_fugit'))
    for k, v of lb
      real_names[k] = robot.brain.userForName(k).real_name or k
    data = {'clocked_in': robot.brain.get('clocked_in'), 'leaderboard': lb, 'real_names': real_names}
    res.end JSON.stringify(data)

  human_leaderboard = (leaderboard) ->
    msg = ""
    for k, v of leaderboard
      realname = robot.brain.userForName(k).real_name or k
      msg += realname + ": " + human_time(v) + "\n"
    if token = null
      msg = stripslack(msg)
    return msg

  robot.on 'clock_in', (username, room) ->
    if not robot.brain.userForName(username)
      return
    if not robot.brain.get('tempus_fugit_available')
      robot.messageRoom room, "*Tempus fugit* not switched on. Talk to your section leader!"
      return
    clocked_in = robot.brain.get('clocked_in') or []
    if username in clocked_in
      msg = "@#{username} Already clocked in!"
    else
      clocked_in.push username
      today = new Date()
      robot.brain.set('clocked_in', clocked_in)
      time_cards = robot.brain.get("tempus_fugit") or {}
      user_time_cards = time_cards[username] or []
      user_time_cards.push today
      time_cards[username] = user_time_cards
      robot.brain.set("tempus_fugit", time_cards)
      msg = "@#{username} clocked in at " + today.getHours() + ":" + forceTwoDigits(today.getMinutes()) + "\n"
      msg += "@#{username} You have clocked up " + human_time(total_time(user_time_cards))
    if token = null
      msg = stripslack(msg)
    robot.messageRoom room, msg

  robot.on 'clock_out', (username, room) ->
    if not robot.brain.userForName(username)
      return
    clocked_in = robot.brain.get('clocked_in') or []
    if username not in clocked_in
      msg = "@#{username} Already clocked out!"
    else
      clocked_in = clocked_in.filter (name) -> name isnt username
      today = new Date()
      robot.brain.set('clocked_in', clocked_in)
      time_cards = robot.brain.get("tempus_fugit") or {}
      user_time_cards = time_cards[username] or []
      user_time_cards.push today
      robot.brain.set("tempus_fugit", time_cards)
      msg = "@#{username} clocked out at " + today.getHours() + ":" + forceTwoDigits(today.getMinutes()) + "\n"
      msg += "@#{username} You have clocked up " + human_time(total_time(user_time_cards))
    if token = null
      msg = stripslack(msg)
    robot.messageRoom room, msg

  robot.respond /finished for the day/i, (res) ->
    if res.message.room is "management"
      clocked_in = robot.brain.get('clocked_in') or []
      for username in clocked_in
        robot.emit 'clock_out', username, "tempus-fugit"
      robot.brain.set('tempus_fugit_available', false)

  robot.respond /open for business/i, (res) ->
    if res.message.room is "management"
      robot.brain.set('tempus_fugit_available', true)
      robot.messageRoom "tempus-fugit", "*Tempus fugit* ready for clock-ins!"

  forceTwoDigits = (val) ->
    if val < 10
      return "0#{val}"
    return val

  stripslack = (toStrip) ->
    toStrip = toStrip.replace(new RegExp('\\*', 'g'), '')
    toStrip = toStrip.replace(new RegExp('\\_', 'g'), '')
    return toStrip

  leaderboard = (time_cards) ->
    totals = {}
    for user, user_time_cards of time_cards
      totals[user] = total_time(user_time_cards)
    res = {}
    totals = do (totals) ->
      keys = Object.keys(totals).sort (a, b) -> totals[b] - totals[a]
      for k in keys
        res[k] = totals[k]
    return res

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
