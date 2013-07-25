util       = require('util')
net        = require('net')
nodemailer = require('../lib/nodemailer')
async      = require('async')

PORT = 11998
HOST = 'localhost'
SECURE = false

oauthConfig =
  user          : 'VALID_EMAIL'
  client_id     : 'VALID_CLIENT_ID'
  client_secret : 'VALID_CLIENT_SECRET'
  refresh_token : 'VALID_REFRESH_TOKEN'
  access_token  : 'VALID_ACCESS_TOKEN'

smtpSettings =
  auth:
    XOAuth2:
      user         : oauthConfig.user
      clientId     : oauthConfig.client_id
      clientSecret : oauthConfig.client_secret
      refreshToken : oauthConfig.refresh_token
      accessToken  : oauthConfig.access_token
  host: HOST
  secureConnection: SECURE
  port: PORT

createServer = () ->
  fakeServer = net.createServer().listen(PORT)
  fakeServer.once 'connection', (socket) ->
    console.log "Got connection"
    async.series [
      (next) ->
        socket.write "220 mx.google.com ESMTP ys4sm54949678pbb.9 - gsmtp\r\n"
        setTimeout(next, 100)

      (next) ->
        socket.write """
250-mx.google.com at your service, [205.189.0.33]\r
250-SIZE 35882577\r
250-8BITMIME\r
250-AUTH LOGIN PLAIN XOAUTH XOAUTH2\r
250-ENHANCEDSTATUSCODES\r
250 PIPELINING\r\n"""
        setTimeout(next, 1000)

      (next) ->
        socket.write "334 eyJzdGF0dXMiOiI0MDAiLCJzY2hlbWVzIjoiQmVhcmVyIiwic2NvcGUiOiJodHRwczovL21haWwuZ29vZ2xlLmNvbS8ifQ==\r\n"
        setTimeout(next, 100)

      (next) ->
        socket.write """
535-5.7.8 Username and Password not accepted. Learn more at\r
535 5.7.8 http://support.google.com/mail/bin/answer.py?answer=14257 fa5sm14061508pbb.3 - gsmtp\r\n"""
        setTimeout(next, 100)

      (next) ->
        # ending the socket here, causes the connection to close in simplesmpt
        socket.end "454 4.7.0 Too many login attempts, please try again later. a8sm54888477qae.11 - gsmtp\r\n"
        setTimeout(next, 100)

    ], () ->
      console.log util.inspect arguments

if require.main == module
  createServer()
  transport = nodemailer.createTransport("SMTP", smtpSettings)
  transport.sendMail {}, (err, results)->
    console.log util.inspect arguments
