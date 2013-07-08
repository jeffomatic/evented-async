evented-async
=============

Event-based extensions for the Node.js async library

## Installation

    npm install evented-async

## timer()

Instruments an async function so it emits timing values when the async callback
is called.

### Example

```js
function task(taskDone) {
  setTimeout(taskDone, 1000);
}

emitter = new events.EventEmitter;
emitter.on('timeToRunTask', function(time) {
  console.log("Time to run task: " + time + "ms");
});

timedTask = eventedAsync.timer(emitter, 'timeToRunTask', task);
timedTask(function(){
  console.log("Timed task complete.")
});
```

## profile()

Syntactic sugar for the `timer` function. `profile` will apply arguments to an async function and emit timing events, eliminating the need to pass a wrapper function to `timer`.

### Example

```js
function slowAdd(arg1, arg2, done) {
  setTimeout(function() {
    done(arg1 + arg2);
  }, 1000);
}

emitter = new events.EventEmitter
emitter.on('timeToSlowAdd', function(time, result) {
  console.log("Time to calculate 5 + 6 = " + result + ": " + time + "ms");
});

eventedAsync.profile(emitter, 'timeToSlowAdd', slowAdd, 5, 6);
```

## Queue class

An event-driven wrapper for `async.queue`. There are two major differences in semantics:

- The `push` and `unshift` methods take a standard comma-separated list of arguments, rather than
  an object that maps argument names to argument values. These methods do not accept callbacks, nor do they support adding multiple tasks at once.
- The queue emits events for the 'saturated', 'empty', and 'drain' callbacks.

### Example

```js
q = new eventedAsync.Queue(function(message, done){
  setTimeout(function(){
    console.log("New message: " + message);
    done();
  }, 1000);
});

q.on('drain', function(){
  console.log("All queued messages have been written.");
});

q.push("Hello...");
q.push("World!");
```