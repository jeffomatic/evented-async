assert = require('assert')
events = require('events')
sinon = require('sinon')

testHelper = require('./test_helper')
eventedAsync = require('../lib/evented_async')

describe 'eventedAsync', ->

  describe '.timer()', ->

    beforeEach ->
      @emitter = new events.EventEmitter
      @eventName = 'testEvent'
      @emitter.on @eventName, (@eventSpy = sinon.spy())

    it 'should broadcast events to the given emitter', (done) ->
      timedFunc = eventedAsync.timer(@emitter, @eventName, (timedSecDone) -> timedSecDone())
      timedFunc =>
        assert @eventSpy.calledOnce
        done()

    it 'should give reasonable timings', (done) ->
      timedFunc = eventedAsync.timer @emitter, @eventName, (timedSecDone) ->
        setTimeout ->
          timedSecDone()
        , 50

      timedFunc =>
        assert @eventSpy.args[0][0] >= 50
        done()

    it 'should pass return values through to the event listener', (done) ->
      timedFunc = eventedAsync.timer @emitter, @eventName, (timedSecDone) ->
        timedSecDone 'testArg1', 'testArg2'

      timedFunc =>
        assert @eventSpy.args[0][1] == 'testArg1'
        assert @eventSpy.args[0][2] == 'testArg2'
        done()

    it 'should pass return values through to the async function callback', (done) ->
      timedFunc = eventedAsync.timer @emitter, @eventName, (timedSecDone) ->
        timedSecDone 'testArg1', 'testArg2'

      timedFunc (arg1, arg2) =>
        assert arg1 == 'testArg1'
        assert arg2 == 'testArg2'
        done()

  describe '.profile()', ->

    beforeEach ->
      @emitter = new events.EventEmitter
      @eventName = 'testEvent'
      @emitter.on @eventName, (@eventSpy = sinon.spy())

    it 'should broadcast events to the given emitter', (done) ->
      eventedAsync.profile @emitter, @eventName,
        (timedSecDone) ->
          timedSecDone()
      , =>
        assert @eventSpy.calledOnce
        done()

    it 'should give reasonable timings', (done) ->
      eventedAsync.profile @emitter, @eventName,
        (timedSecDone) ->
          setTimeout ->
            timedSecDone()
          , 50
      , =>
        assert @eventSpy.args[0][0] >= 50
        done()

    it 'should pass return values through to the event listener', (done) ->
      eventedAsync.profile @emitter, @eventName,
        (timedSecDone) ->
          timedSecDone 'testArg1', 'testArg2'
      , =>
        assert @eventSpy.args[0][1] == 'testArg1'
        assert @eventSpy.args[0][2] == 'testArg2'
        done()

    it 'should pass return values through to the async function callback', (done) ->
      eventedAsync.profile @emitter, @eventName,
        (timedSecDone) ->
          timedSecDone 'testArg1', 'testArg2'
      , (arg1, arg2) =>
        assert arg1 == 'testArg1'
        assert arg2 == 'testArg2'
        done()

    it 'should pass the given arguments to the async functions', (done) ->
      eventedAsync.profile @emitter, @eventName,
        (arg1, arg2, timedSecDone) ->
          assert arg1 == 'testArg1'
          assert arg2 == 'testArg2'
          timedSecDone()
      , 'testArg1'
      , 'testArg2'
      , done

  describe 'Queue class', ->

    it 'should forward arugments to the wrapped task function', (done) ->
      receivedArg1 = null
      receivedArg2 = null

      task = (arg1, arg2, taskDone) ->
        receivedArg1 = arg1
        receivedArg2 = arg2
        process.nextTick taskDone

      testArg1 = 'arg1'
      testArg2 = 'arg2'

      q = new eventedAsync.Queue(task)
      q.on 'drain', ->
        assert.equal testArg1, receivedArg1
        assert.equal testArg2, receivedArg2
        done()
      q.push testArg1, testArg2

    it 'should wait until all exceptions have been handled', (done) ->
      tasksDoneCount = 0
      task = (taskDone) =>
          tasksDoneCount += 1
          setTimeout taskDone, 10

      q = new eventedAsync.Queue(task)
      q.once 'drain', ->
        assert.equal tasksDoneCount, 3
        done()

      setTimeout (-> q.push()), 5
      setTimeout (-> q.push()), 10
      setTimeout (-> q.push()), 15
      setTimeout (-> q.push()), 50 # Should drain once before clearing this error