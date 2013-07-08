_ = require('underscore')
async = require('async')
events = require('events')

lib =

  timer: (emitter, eventName, asyncFunc) ->
    (args...) ->
      if _.isFunction(args[args.length - 1])
        done = args.pop()
      else
        done = null

      startTime = Date.now()
      asyncFunc args..., (results...) ->
        # We pass the results to the emitter in case the event handler needs to
        # discriminate between result cases, such as errors.
        emitter.emit eventName, Date.now() - startTime, results...
        done(results...) if done

  profile: (emitter, eventName, asyncFunc, asyncFuncArgs...) ->
    timerFunc = lib.timer(emitter, eventName, asyncFunc)
    timerFunc asyncFuncArgs...

  Queue: class extends events.EventEmitter

    constructor: (task, concurrency = 1) ->
      @q = async.queue ({args}, done) ->
        task args..., done
      , concurrency

      @q.saturated = => @emit 'saturated'
      @q.empty = => @emit 'empty'
      @q.drain = => @emit 'drain'

    push: (args...) ->
      @q.push args: args

    unshift: (args...) ->
      @q.unshift args: args

    length: () ->
      @q.length()

    # Gets/sets the async queue's concurrency limit
    concurrency: (concurrency) ->
      if concurrency?
        @q.concurrency = concurrency
      else
        @q.concurrency

module.exports = lib
